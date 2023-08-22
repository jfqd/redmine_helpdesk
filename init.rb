require 'redmine'
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require 'helpdesk_hooks'
require 'helpdesk_mailer'
require 'redmine_helpdesk/journal_patch'
require 'redmine_helpdesk/mail_handler_patch'
require 'redmine_helpdesk/mailer_patch'

Redmine::Plugin.register :redmine_helpdesk do
  name 'Redmine helpdesk plugin'
  author 'Stefan Husch'
  description 'Redmine helpdesk plugin'
  version '0.0.20'
  requires_redmine :version_or_higher => '5.0.0'
  project_module :issue_tracking do
    permission :treat_user_as_supportclient, {}
  end
end
