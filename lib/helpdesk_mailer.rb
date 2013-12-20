#
# With Rails 3 mail is send with the mail method. Sadly redmine
# uses this method-name too in their mailer. This is the reason
# why we need our own Mailer class.
#
class HelpdeskMailer < ActionMailer::Base
  helper :application

  include Redmine::I18n

  # set the hostname for url_for helper
  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end
  
  # Sending email notifications to the supportclient
  def email_to_supportclient(issue, recipient, cc_email='', journal=nil, text='')
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id issue
    subject = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
    # Set 'from' email-address to 'helpdesk-sender-email' if available.
    # Falls back to regular redmine behaviour if 'sender' is empty.
    p = issue.project
    s = CustomField.find_by_name('helpdesk-sender-email')
    sender = p.custom_value_for(s).try(:value) if p.present? && s.present?
    # If a custom field with text for the first reply is
    # available then use this one instead of the regular
    r = CustomField.find_by_name('helpdesk-first-reply')
    f = CustomField.find_by_name('helpdesk-email-footer')
    reply  = p.nil? || r.nil? ? '' : p.custom_value_for(r).try(:value)
    footer = p.nil? || f.nil? ? '' : p.custom_value_for(f).try(:value)
    # add any attachements
    if journal.present? && text.present?
      journal.details.each do |d|
        if d.property == 'attachment'
          a = Attachment.find(d.prop_key)
          begin
            attachments[a.filename] = File.read(a.diskfile)
          rescue
            # ignore rescue
          end
        end
      end
    end
    # create mail object to deliver
    mail = if text.present?
      # sending out the journal note to the support client
      @footer = footer.gsub("##issue-id##", issue.id.to_s)
      @text = text
      @journal = journal
      mail(
        :from    => sender.present? && sender || Setting.mail_from,
        :to      => recipient,
        :cc      => cc_email,
        :subject => subject,
        :date    => Time.zone.now
      )
    elsif reply.present?
      # sending out the first reply message
      @footer = footer.gsub("##issue-id##", issue.id.to_s)
      @text = reply.gsub("##issue-id##", issue.id.to_s)
      mail(
        :from    => sender.present? && sender || Setting.mail_from,
        :to      => recipient,
        :cc      => cc_email,
        :subject => subject,
        :date    => Time.zone.now
      )
    else
      # fallback to a regular notifications email with redmine view
      @issue = issue
      @journal = journal
      @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
      mail(
        :from    => sender.present? && sender || Setting.mail_from,
        :to      => recipient,
        :cc      => cc_email,
        :subject => subject,
        :date    => Time.zone.now,
        :template_path => 'mailer',
        :template_name => 'issue_edit'
      )
    end
    # return mail object to deliver it
    return mail
  end

  private

  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-Redmine-#{k}"] = v.to_s }
  end

  def message_id(object)
    @message_id_object = object
  end
  
end
