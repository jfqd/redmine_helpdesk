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
  requires_redmine :version_or_higher => '7.0.0'
  settings default: { 'default_sla_first_response' => '4', 'default_sla_resolution' => '24' }, partial: 'settings/helpdesk_settings'
  project_module :issue_tracking do
    permission :treat_user_as_supportclient, {}
    permission :manage_helpdesk_settings, { helpdesk_inbound: [:project_settings, :save_project_settings, :escalate, :dashboard, :merge] }
  end
end
