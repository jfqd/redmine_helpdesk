require 'redmine'
require 'helpdesk_hooks'
require 'journal_patch'
require 'mail_handler_patch'
require 'mailer_patch'

Redmine::Plugin.register :redmine_helpdesk do
  name 'Redmine helpdesk plugin'
  author 'Stefan Husch'
  description 'Redmine helpdesk plugin for netz98.de'
  version '0.0.12'
  requires_redmine :version_or_higher => '2.4.0'
  project_module :issue_tracking do
    permission :treat_user_as_supportclient, {}
  end
end
