require 'redmine'
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require 'helpdesk_hooks'
require 'helpdesk_mailer'
require 'redmine_helpdesk/journal_patch'
require 'redmine_helpdesk/mail_handler_patch'
require 'redmine_helpdesk/mailer_patch'

Redmine::Plugin.register :redmine_helpdesk do
  name 'Redmine Enterprise Helpdesk'
  author 'Arean Narrayan'
  author_url 'https://github.com/Arean82'
  url 'https://github.com/Arean82/redmine_helpdesk'
  description 'Multi-domain enterprise helpdesk with instant inbound email, SLA tracking, canned responses, and cross-project escalation'
  version '1.0.0'
  requires_redmine :version_or_higher => '6.0.0'
  settings default: { 'default_sla_first_response' => '4', 'default_sla_resolution' => '24', 'webhook_secret' => '' }, partial: 'settings/helpdesk_settings'
  menu :project_menu, :redmine_helpdesk, { controller: 'helpdesk_inbound', action: 'dashboard' }, caption: 'Helpdesk', param: :project_id, if: Proc.new { |p| ((Setting.plugin_redmine_helpdesk || {})["project_#{p.id}"] || {})['enabled'] == '1' }
  project_module :issue_tracking do
    permission :treat_user_as_supportclient, {}
    permission :manage_helpdesk_settings, { helpdesk_inbound: [:project_settings, :save_project_settings, :escalate, :dashboard, :merge] }
  end
end

if Rails.env.production? && !defined?(Rake) && !defined?(Rails::Console)
  Thread.new do
    loop do
      sleep 60
      begin
        settings = Setting.plugin_redmine_helpdesk || {}
        settings.each do |key, cfg|
          next unless key.start_with?('project_') && cfg.is_a?(Hash) && cfg['enabled'] == '1'
          next if cfg['imap_host'].blank? || cfg['imap_username'].blank?
          proj_id = key.sub('project_', '').to_i
          project = Project.find_by(id: proj_id)
          next unless project
          Redmine::IMAP.check(
            { host: cfg['imap_host'], port: (cfg['imap_port'] || 993).to_i, ssl: true, username: cfg['imap_username'], password: cfg['imap_password'].to_s, folder: 'INBOX' },
            { issue: { project: project.identifier }, unknown_user: 'accept', no_permission_check: '1' }
          )
        end
      rescue
      end
    end
  end
end
