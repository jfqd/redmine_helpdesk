class HelpdeskHooks < Redmine::Hook::ViewListener
  render_on :view_issues_show_details_bottom, :partial => 'helpdesk/issue_sla_and_canned'

  # Show send-to-owner checkbox on issue edit/new when owner-email custom field is present
  def view_issues_form_details_bottom(context = {})
    issue = context[:issue]
    return '' unless issue && issue.project
    c = CustomField.find_by(name: 'owner-email')
    return '' unless c
    owner_email = issue.custom_value_for(c)&.value
    return '' if owner_email.blank?
    "<p><label>#{l(:label_send_to_owner, default: 'Send reply to customer')}</label>#{check_box_tag('send_to_owner', '1', true)}</p>".html_safe
  end
end
