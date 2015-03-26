require File.dirname(__FILE__) + '/../test_helper'

class IssuesControllerWithHelpdeskTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :all

  def setup
    User.current = nil
    @controller = IssuesController.new
  end

  def test_render_send_to_owner_checkbox
    issue = Issue.find(1)
    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_select "#send_to_owner", 1
  end

  test "send_to_owner not renderer without owner-email" do
    issue = Issue.find(1)
    owner_field = CustomField.find_by_name('owner-email')
    owner_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.id, owner_field.id).
      first
    owner_value.value = ""
    owner_value.save!

    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_select "#send_to_owner", 0
  end

  test "send_to_owner checked if send-to-owner-default is set to yes" do
    issue = Issue.find(1)
    default_field = CustomField.find_by_name('helpdesk-send-to-owner-default')
    default_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.project.id, default_field.id).
      first
    default_value.value = "1"
    default_value.save!

    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_select "#send_to_owner", 1
    assert_equal "checked", css_select("#send_to_owner").first["checked"]
  end

  test "send_to_owner checked if send-to-owner-default is set to no" do
    issue = Issue.find(1)
    default_field = CustomField.find_by_name('helpdesk-send-to-owner-default')
    default_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.project.id, default_field.id).
      first
    default_value.value = "2"
    default_value.save!

    @request.session[:user_id] = 1
    get :edit, :id => 1
    assert_response :success
    assert_select "#send_to_owner", 1
    assert_not_equal "checked", css_select("#send_to_owner").first["checked"]
  end

  test "history note added to journal if note has been sent to owner" do
    issue = Issue.find(1)
    journal = issue.journals.first
    journal.send_to_owner = true
    journal.save

    @request.session[:user_id] = 1
    get :show, :id => 1
    assert_response :success

    assert_select "#history>i", 1
    assert_select "#history>i", "This answer was sent to the supportclient."
  end

  test "history note not added to journal if note has not been sent to owner" do
    issue = Issue.find(1)
    journal = issue.journals.first
    journal.send_to_owner = false
    journal.save

    @request.session[:user_id] = 1
    get :show, :id => 1
    assert_response :success

    assert_select "#history>i", 0
  end

  test "send_to_owner checked" do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
    @request.session[:user_id] = 1
    assert_difference('Journal.count') do
      put :update, :id => 1,
                   :issue => {:assigned_to_id => 1,
                              :notes => 'Assigned'},
                   :send_to_owner => "true"
    end
    assert_redirected_to :action => 'show', :id => '1'

    assert Issue.find(1).journals.last.send_to_owner
    mail = ActionMailer::Base.deliveries.last
    assert_equal "owner@example.com",  mail.to.first
    assert_equal "Assigned\n\nemail footer", mail.body.to_s
  end

  test "send_to_owner not checked" do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
    @request.session[:user_id] = 1
    assert_difference('Journal.count') do
      put :update, :id => 1,
                   :issue => {:assigned_to_id => 1,
                              :notes => 'Assigned'},
                   :send_to_owner => "false"
    end
    assert_redirected_to :action => 'show', :id => '1'

    assert !Issue.find(1).journals.last.send_to_owner
    ActionMailer::Base.deliveries.each do |mail|
      assert !mail.to.include?("owner@example.com")
    end
  end
end
