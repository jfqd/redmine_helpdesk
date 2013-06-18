require 'redmine'
require 'helpdesk_hooks'
require 'mailer_patch'
require 'mail_handler_patch'
require 'journal_observer_patch'

Redmine::Plugin.register :redmine_helpdesk do
  name 'Redmine helpdesk plugin'
  author 'Stefan Husch'
  description 'Redmine helpdesk plugin for netz98.de'
  version '0.0.4'
  requires_redmine :version_or_higher => '2.3.0'
end
