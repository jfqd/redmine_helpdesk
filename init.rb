require 'redmine'
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require 'helpdesk_hooks'
require 'helpdesk_mailer'
require 'redmine_helpdesk_journal_patch'
require 'redmine_helpdesk_mail_handler_patch'
require 'redmine_helpdesk_mailer_patch'

Redmine::Plugin.register :redmine_helpdesk do
  name 'Redmine helpdesk plugin'
  author 'Stefan Husch'
  description 'Redmine helpdesk plugin'
  version '0.0.19'
  requires_redmine :version_or_higher => '4.0.0'
  project_module :issue_tracking do
    permission :treat_user_as_supportclient, {}
  end
end
