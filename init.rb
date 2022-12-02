require 'redmine'

# manually load modules (required for redmine:email:receive_imap rake task)
require File.expand_path('../lib/redmine_helpdesk/patches/mail_handler_patch',__FILE__)
require File.expand_path('../lib/helpdesk_mailer',__FILE__)
require File.expand_path('../lib/macro_expander',__FILE__)

Redmine::Plugin.register :redmine_helpdesk do
  name 'Redmine helpdesk plugin'
  author 'Stefan Husch'
  description 'Redmine helpdesk plugin'
  version '0.1.0'
  requires_redmine :version_or_higher => '5.0.0'
  project_module :issue_tracking do
    permission :treat_user_as_supportclient, {}
  end
end
