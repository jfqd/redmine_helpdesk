require File.dirname(__FILE__) + '/../test_helper'

class MailHandlerPatchTest < ActiveSupport::TestCase
  include Redmine::I18n

  self.use_transactional_fixtures = true

  fixtures :all

  def setup
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = Redmine::Notifiable.all.collect(&:name)
  end

  def teardown
    Setting.clear_cache
  end

  def test_helpdesk_dispatch_not_supportclient
    HelpdeskMailer.any_instance.expects(:email_to_supportclient).never
    issue = submit_email('ticket_by_user_1.eml',
                         :issue => {:project => 'helpdesk_project_1'},
                         :unknown_user => 'accept',
                         :no_permission_check => 1)
    assert_issue_created issue

    owner_field = CustomField.find_by_name('owner-email')
    owner_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.id, owner_field.id).
      first
    assert owner_value.value.blank?
    assert User.find(1).login, issue.author.login
  end

  def test_helpdesk_dispatch_disabled_copy_to
    assert_no_difference 'User.count' do
      HelpdeskMailer.any_instance.expects(:email_to_supportclient).with(
        kind_of(Issue),  {:recipient =>"john.doe@somenet.foo", 
                          :carbon_copy => nil}
      ).once
      issue = submit_email('ticket_by_unknown_user_with_cc.eml',
                       :issue => {:project => 'helpdesk_project_4'},
                       :unknown_user => 'accept',
                       :no_permission_check => 1)
      assert_issue_created issue

      owner_field = CustomField.find_by_name('owner-email')
      owner_value = CustomValue.where(
          "customized_id = ? AND custom_field_id = ?", issue.id, owner_field.id).
          first
      assert_equal "john.doe@somenet.foo", owner_value.value
      assert issue.author.anonymous?
    end
  end

  def test_helpdesk_dispatch_anonymous_as_supportclient
    assert_no_difference 'User.count' do
      HelpdeskMailer.any_instance.expects(:email_to_supportclient).with(
        kind_of(Issue), {:recipient =>"john.doe@somenet.foo", :carbon_copy => nil}).once
      issue = submit_email('ticket_by_unknown_user.eml',
                       :issue => {:project => 'helpdesk_project_1'},
                       :unknown_user => 'accept',
                       :no_permission_check => 1)
      assert_issue_created issue

      owner_field = CustomField.find_by_name('owner-email')
      owner_value = CustomValue.where(
          "customized_id = ? AND custom_field_id = ?", issue.id, owner_field.id).
          first
      assert_equal "john.doe@somenet.foo", owner_value.value
      assert issue.author.anonymous?
    end
  end

  def test_helpdesk_dispatch_anonymous_as_supportclient_with_cc
    assert_no_difference 'User.count' do
      HelpdeskMailer.any_instance.expects(:email_to_supportclient).with(
        kind_of(Issue),  {:recipient =>"john.doe@somenet.foo", 
                          :carbon_copy => "Ada <ada@test.lindsaar.net>, mikel@test.lindsaar.net, Bob <bob@test.lindsaar.net>"}
      ).once
      issue = submit_email('ticket_by_unknown_user_with_cc.eml',
                       :issue => {:project => 'helpdesk_project_1'},
                       :unknown_user => 'accept',
                       :no_permission_check => 1)
      assert_issue_created issue

      owner_field = CustomField.find_by_name('owner-email')
      owner_value = CustomValue.where(
          "customized_id = ? AND custom_field_id = ?", issue.id, owner_field.id).
          first
      copy_to_field = CustomField.find_by_name('copy-to')
      copy_to_value = CustomValue.where(
          "customized_id = ? AND custom_field_id = ?", issue.id, copy_to_field.id).
          first
      assert_equal "john.doe@somenet.foo", owner_value.value
      assert issue.author.anonymous?
      assert_equal "Ada <ada@test.lindsaar.net>, mikel@test.lindsaar.net, Bob <bob@test.lindsaar.net>",
          copy_to_value.value
    end
  end

  def test_helpdesk_dispatch_supportclient
    HelpdeskMailer.any_instance.expects(:email_to_supportclient).with(kind_of(Issue), 
        {:recipient => User.find(2).mail, :carbon_copy => nil})
    issue = submit_email('ticket_by_user_2.eml',
                         :issue => {:project => 'helpdesk_project_2'},
                         :unknown_user => 'accept',
                         :no_permission_check => 1)
    assert_issue_created issue

    owner_field = CustomField.find_by_name('owner-email')
    owner_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.id, owner_field.id).
      first
    assert_equal User.find(2).mail, owner_value.value
    assert User.find(2).login, issue.author.login
  end

  # TODO: Attachments

  def submit_email(filename, options={})
    raw = IO.read(File.join(TestHelper.files_path, 'mail_handler', filename))
    yield raw if block_given?
    MailHandler.receive(raw, options)
  end

  def assert_issue_created(issue)
    assert issue.is_a?(Issue)
    assert !issue.new_record?
    issue.reload
  end
end
