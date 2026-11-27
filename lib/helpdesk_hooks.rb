class HelpdeskHooks < Redmine::Hook::ViewListener
  render_on :view_issues_show_details_bottom, :partial => 'helpdesk/issue_sla_and_canned'
end
