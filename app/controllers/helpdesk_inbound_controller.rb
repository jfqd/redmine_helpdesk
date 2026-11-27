class HelpdeskInboundController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:receive]
  before_action :find_project_by_project_id, only: [:project_settings, :save_project_settings, :dashboard, :reports, :test_smtp, :contacts, :public_new, :public_create]
  before_action :authorize_unless_admin, only: [:project_settings, :save_project_settings, :dashboard, :reports, :test_smtp, :contacts]
  skip_before_action :check_if_login_required, only: [:receive, :public_new, :public_create, :csat, :public_status, :public_reply, :widget], raise: false

  accept_api_auth :receive, :escalate

  # Instant inbound email webhook (Mailgun / SendGrid / Postmark / Postfix pipe)
  def receive
    secret = (Setting.plugin_redmine_helpdesk || {})['webhook_secret'].to_s.strip
    if secret.present? && params[:secret].to_s != secret && request.headers['X-Helpdesk-Secret'].to_s != secret
      render json: { error: 'Unauthorized webhook secret' }, status: :unauthorized
      return
    end

    raw_email = params[:raw_email] || params[:body_mime] || request.raw_post
    if raw_email.blank?
      render json: { error: 'Empty email payload' }, status: :bad_request
      return
    end

    # Route to project by recipient email if configured
    to_addr = params[:recipient].to_s.downcase.strip
    target_project = find_project_by_helpdesk_email(to_addr)

    if target_project
      cfg = (Setting.plugin_redmine_helpdesk || {})["project_#{target_project.id}"] || {}
      blacklist = cfg['blacklist_domains'].to_s.split(',').map(&:strip).reject(&:blank?)
      sender_str = params[:sender].to_s.downcase
      if blacklist.any? { |b| sender_str.include?(b.downcase) }
        render json: { error: 'Sender is blacklisted' }, status: :forbidden
        return
      end
      att_blacklist = cfg['attachment_blacklist'].to_s.split(',').map { |e| e.strip.downcase }.reject(&:blank?)
      if att_blacklist.any? && att_blacklist.any? { |ext| raw_email.downcase.include?("filename=\"") && raw_email.downcase.include?(ext) }
        render json: { error: 'Blocked attachment extension' }, status: :forbidden
        return
      end
    end

    options = {}
    options[:issue] = { project: target_project.identifier } if target_project

    if MailHandler.receive(raw_email, options)
      render json: { status: 'ok', routed_project: target_project&.identifier }, status: :created
    else
      render json: { error: 'Failed to process email' }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Escalate a helpdesk ticket into a developer task in another project
  def escalate
    ticket = Issue.find(params[:id])
    target_project = Project.find(params[:target_project_id])
    dev_task = Issue.new(
      project: target_project,
      tracker: target_project.trackers.first,
      author: User.current,
      assigned_to_id: params[:assigned_to_id],
      subject: "[Escalated ##{ticket.id}] #{ticket.subject}",
      description: "Escalated from Helpdesk Ticket ##{ticket.id} (#{ticket.project.name}):\n\n#{ticket.description}",
      is_private: true
    )
    if dev_task.save
      IssueRelation.create(issue_from: ticket, issue_to: dev_task, relation_type: IssueRelation::TYPE_RELATES)
      flash[:notice] = "Escalated to ##{dev_task.id} in #{target_project.name}"
    else
      flash[:error] = dev_task.errors.full_messages.join(', ')
    end
    redirect_to issue_path(ticket)
  end

  def public_status
    if params[:ticket_id].present?
      @ticket = Issue.find_by(id: params[:ticket_id].to_i)
    end
  end

  def public_reply
    ticket = Issue.find(params[:ticket_id].to_i)
    if params[:reply_text].present?
      ticket.init_journal(User.anonymous, "Customer Reply (#{params[:customer_email]}):\n\n#{params[:reply_text]}")
      ticket.save
      flash[:notice] = 'Reply added to ticket.'
    end
    redirect_to helpdesk_public_status_path(ticket_id: ticket.id)
  end

  def widget
    @project = Project.find_by(identifier: params[:project_id]) || Project.find_by(id: params[:project_id])
    render content_type: 'application/javascript', plain: <<~JS
      (function(){
        var btn = document.createElement('a');
        btn.href = '#{helpdesk_public_new_url(@project)}';
        btn.target = '_blank';
        btn.textContent = 'Support';
        btn.style.cssText = 'position:fixed;bottom:20px;right:20px;background:#2563eb;color:#fff;padding:10px 18px;border-radius:999px;font-family:sans-serif;font-size:14px;font-weight:600;text-decoration:none;box-shadow:0 4px 12px rgba(0,0,0,0.15);z-index:9999;';
        document.body.appendChild(btn);
      })();
    JS
  end

  def gdpr_anonymize
    ticket = Issue.find(params[:id])
    ticket.description = ticket.description.to_s.gsub(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/, '[REDACTED_EMAIL]')
    ticket.init_journal(User.current, 'GDPR: Customer PII anonymized.')
    ticket.save
    flash[:notice] = "Ticket ##{ticket.id} anonymized."
    redirect_to issue_path(ticket)
  end

  def test_smtp
    cfg = (Setting.plugin_redmine_helpdesk || {})["project_#{@project.id}"] || {}
    host = cfg['smtp_address'].to_s.strip
    port = (cfg['smtp_port'] || 587).to_i
    if host.blank?
      flash[:error] = 'SMTP Host is blank.'
    else
      begin
        require 'net/smtp'
        Net::SMTP.start(host, port) { |smtp| smtp.finish }
        flash[:notice] = "SMTP connection to #{host}:#{port} succeeded!"
      rescue => e
        flash[:error] = "SMTP connection failed: #{e.message}"
      end
    end
    redirect_to project_helpdesk_settings_path(@project)
  end

  def contacts
    @issues = @project.issues.order(created_on: :desc).limit(100)
    @contacts = @issues.map { |i| i.description.to_s.lines.first.to_s.strip }.select { |l| l.start_with?('From:') }.map { |l| l.sub('From:', '').strip }.uniq
  end

  def reports
    @cfg = (Setting.plugin_redmine_helpdesk || {})["project_#{@project.id}"] || {}
    @total_tickets = @project.issues.count
    @open_count = @project.issues.open.count
    @closed_count = @total_tickets - @open_count
    res_hours = (@cfg['sla_resolution_hours'] || 24).to_i
    @breached_count = @project.issues.open.select { |i| ((Time.now - i.created_on) / 3600.0) > res_hours }.size
  end

  def csat
    issue = Issue.find(params[:id])
    rating = params[:rating].to_s
    if %w[happy neutral unhappy].include?(rating)
      s = Setting.plugin_redmine_helpdesk || {}
      s["csat_#{issue.id}"] = rating
      Setting.plugin_redmine_helpdesk = s
      render plain: "Thank you for your feedback (#{rating}) on Ticket ##{issue.id}."
    else
      render plain: 'Invalid rating', status: :bad_request
    end
  end

  def public_new
    @helpdesk_config = (Setting.plugin_redmine_helpdesk || {})["project_#{@project.id}"] || {}
  end

  def public_create
    issue = Issue.new(
      project: @project,
      tracker: @project.trackers.first,
      author: User.anonymous,
      subject: params[:subject].to_s.strip,
      description: "From: #{params[:customer_email]}\n\n#{params[:description]}"
    )
    if issue.save
      if issue.subject.downcase.include?('urgent') || issue.subject.downcase.include?('down') || issue.subject.downcase.include?('outage')
        urgent_prio = IssuePriority.where("LOWER(name) IN ('urgent', 'immediate', 'high')").order(position: :desc).first
        issue.update(priority: urgent_prio) if urgent_prio
      end
      cfg = (Setting.plugin_redmine_helpdesk || {})["project_#{@project.id}"] || {}
      if cfg['auto_reply_enabled'] == '1' && params[:customer_email].present?
        first_reply_cf = CustomField.find_by(name: 'helpdesk-first-reply')
        reply_msg = first_reply_cf ? @project.custom_value_for(first_reply_cf)&.value : nil
        reply_msg = "Thank you for contacting support. Your ticket ##{issue.id} has been received." if reply_msg.blank?
        issue.init_journal(User.anonymous, reply_msg)
        issue.save
        begin
          HelpdeskMailer.email_to_supportclient(issue, { recipient: params[:customer_email], text: reply_msg }).deliver_later
        rescue
          HelpdeskMailer.email_to_supportclient(issue, { recipient: params[:customer_email], text: reply_msg }).deliver_now rescue nil
        end
      end
      flash[:notice] = "Ticket ##{issue.id} submitted successfully."
      redirect_to helpdesk_public_new_path(@project)
    else
      flash[:error] = issue.errors.full_messages.join(', ')
      redirect_to helpdesk_public_new_path(@project)
    end
  end

  def dashboard
    @cfg = (Setting.plugin_redmine_helpdesk || {})["project_#{@project.id}"] || {}
    @open_tickets = @project.issues.open.order(updated_on: :desc).limit(50)
    @unassigned_tickets = @open_tickets.select { |i| i.assigned_to_id.nil? }
    @my_tickets = @open_tickets.select { |i| i.assigned_to_id == User.current.id }
    res_hours = (@cfg['sla_resolution_hours'] || 24).to_i
    @sla_breached = @open_tickets.select { |i| ((Time.now - i.created_on) / 3600.0) > res_hours }
  end

  def merge
    source = Issue.find(params[:id])
    target = Issue.find(params[:target_issue_id])
    source.journals.update_all(journalized_id: target.id)
    target.init_journal(User.current, "Merged ticket ##{source.id} (#{source.subject}) into this ticket.")
    target.save
    source.status = IssueStatus.where(is_closed: true).first || source.status
    source.save
    flash[:notice] = "Merged ##{source.id} into ##{target.id}"
    redirect_to issue_path(target)
  end

  def project_settings
    @helpdesk_config = (Setting.plugin_redmine_helpdesk || {})["project_#{@project.id}"] || {}
  end

  def save_project_settings
    s = Setting.plugin_redmine_helpdesk || {}
    s["project_#{@project.id}"] = {
      'enabled' => params[:enabled] == '1' ? '1' : '0',
      'sender_email' => params[:sender_email].to_s.strip,
      'reply_to' => params[:reply_to].to_s.strip,
      'smtp_address' => params[:smtp_address].to_s.strip,
      'smtp_port' => params[:smtp_port].present? ? params[:smtp_port].to_i : 587,
      'smtp_username' => params[:smtp_username].to_s.strip,
      'smtp_password' => params[:smtp_password].to_s,
      'smtp_tls' => params[:smtp_tls] == '1' ? '1' : '0',
      'imap_host' => params[:imap_host].to_s.strip,
      'imap_port' => params[:imap_port].present? ? params[:imap_port].to_i : 993,
      'imap_username' => params[:imap_username].to_s.strip,
      'imap_password' => params[:imap_password].to_s,
      'auth_mode' => params[:auth_mode].to_s,
      'oauth_tenant_id' => params[:oauth_tenant_id].to_s.strip,
      'oauth_client_id' => params[:oauth_client_id].to_s.strip,
      'oauth_client_secret' => params[:oauth_client_secret].to_s,
      'blacklist_domains' => params[:blacklist_domains].to_s.strip,
      'attachment_blacklist' => params[:attachment_blacklist].to_s.strip,
      'auto_priority_keywords' => params[:auto_priority_keywords].to_s.strip,
      'auto_reply_enabled' => params[:auto_reply_enabled] == '1' ? '1' : '0',
      'sla_first_response_hours' => params[:sla_first_response_hours].to_i,
      'sla_resolution_hours' => params[:sla_resolution_hours].to_i,
      'canned_responses' => params[:canned_responses].to_s
    }
    Setting.plugin_redmine_helpdesk = s
    flash[:notice] = l(:notice_successful_update)
    redirect_to project_helpdesk_settings_path(@project)
  end

  private

  def authorize_unless_admin
    return true if User.current.admin?
    authorize
  end

  def find_project_by_helpdesk_email(email)
    return nil if email.blank?
    settings = Setting.plugin_redmine_helpdesk || {}
    settings.each do |key, val|
      next unless key.start_with?('project_') && val.is_a?(Hash)
      if val['enabled'] == '1' && val['sender_email'].to_s.downcase.strip == email
        proj_id = key.sub('project_', '').to_i
        return Project.find_by(id: proj_id)
      end
    end
    nil
  end
end
