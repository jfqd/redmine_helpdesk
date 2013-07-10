require 'redmine'
require 'helpdesk_hooks'
require 'helpdesk_mailer'
require 'journal_observer_patch'
require 'mail_handler_patch'
require 'mailer_patch'

Redmine::Plugin.register :redmine_helpdesk do
  name 'Redmine helpdesk plugin'
  author 'Stefan Husch'
  description 'Redmine helpdesk plugin for netz98.de'
  version '0.0.5'
  requires_redmine :version_or_higher => '2.3.0'
end
