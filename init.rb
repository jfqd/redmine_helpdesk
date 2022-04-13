require 'redmine'

Redmine::Plugin.register :redmine_helpdesk do
  name 'Redmine helpdesk plugin'
  author 'Stefan Husch'
  description 'Redmine helpdesk plugin'
  version '0.0.18'
  requires_redmine :version_or_higher => '4.0.0'
  project_module :issue_tracking do
    permission :treat_user_as_supportclient, {}
  end
end
