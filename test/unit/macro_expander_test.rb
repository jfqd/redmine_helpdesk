require File.dirname(__FILE__) + '/../test_helper'

class MacroExpanderTest < ActionMailer::TestCase
  include Redmine::I18n

  self.use_transactional_fixtures = true

  fixtures :all

  def setup
    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'
    Setting.default_language = 'en'
    User.current = nil
  end

  def teardown
    Setting.clear_cache
  end

  def test_expand_issue
    issue = Issue.find(1)
    s = CustomField.find_by_name('helpdesk-email-footer')
    custom_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.project.id, s.id).
      first
    custom_value.value = "##issue-id##, ##issue-subject##, ##issue-tracker##, ##issue-status##"
    custom_value.save
    email = HelpdeskMailer.
        email_to_supportclient(
            issue,
            {
                :recipient => "owner@example.com",
                :journal   => Journal.find(1),
                :text      => 'text'
            }).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert "text\n\n#{issue.id}, #{issue.subject}, #{issue.tracker}, #{issue.status}", email.body.to_s
  end

  def test_expand_project
    issue = Issue.find(1)
    s = CustomField.find_by_name('helpdesk-email-footer')
    custom_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.project.id, s.id).
      first
    custom_value.value = "##project-name##"
    custom_value.save
    email = HelpdeskMailer.
        email_to_supportclient(
            issue,
            { 
                :recipient => "owner@example.com",
                :journal   => Journal.find(1),
                :text      =>'text'
            }).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert "text\n\n#{issue.project.name}", email.body.to_s
  end

  def test_expand_user
    issue = Issue.find(1)
    s = CustomField.find_by_name('helpdesk-email-footer')
    custom_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.project.id, s.id).
      first
    custom_value.value = "##user-name##, ##user-firstname##, ##user-lastname##, ##user-mail##, ##user-login##"
    custom_value.save
    email = HelpdeskMailer.
        email_to_supportclient(
            issue,
            {
                :recipient => "owner@example.com",
                :journal   => Journal.find(1),
                :text      => 'text'
            }).deliver
    assert !ActionMailer::Base.deliveries.empty?
    user = Journal.find(1).user
    assert "text\n\n#{user.name}, #{user.firstname}, #{user.lastname}, #{user.mail}, #{user.login}", email.body.to_s
  end

  def test_expand_user_cfs_w_not_existing
    issue = Issue.find(1)
    user = Journal.find(1).user
    s = CustomField.find_by_name('helpdesk-email-footer')
    custom_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.project.id, s.id).
      first
    custom_value.value = "##user-cf-title##, ##user-cf-motto##, ##user-cf-invalid##."
    custom_value.save

    title = CustomField.find_by_name('title')
    custom_value = CustomValue.new(
      :customized_id => user.id,
      :custom_field_id => title.id,
      :value => "junior senior"
    )
    custom_value.save
    motto = CustomField.find_by_name('motto')
    custom_value = CustomValue.new(
      :customized_id => user.id,
      :custom_field_id => motto.id,
      :value => "epic motto"
    )
    custom_value.save

    email = HelpdeskMailer.
        email_to_supportclient(
            issue,
            {:recipient => "owner@example.com",
             :journal   => Journal.find(1),
             :text      =>'text'
            }).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert "text\n\njunior senior, epic motto, .", email.body.to_s
  end

  def test_expand_user_no_cfs
    issue = Issue.find(1)
    user = Journal.find(1).user
    s = CustomField.find_by_name('helpdesk-email-footer')
    custom_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.project.id, s.id).
      first
    custom_value.value = "##user-cf-title##, ##user-cf-motto##, ##user-cf-invalid##."
    custom_value.save

    email = HelpdeskMailer.
        email_to_supportclient(
            issue,
            {
                :recipient => "owner@example.com",
                :journal   => Journal.find(1),
                :text      => 'text'
            }).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert "text\n\n, , .", email.body.to_s
  end

  def test_expand_base
    issue = Issue.find(1)
    s = CustomField.find_by_name('helpdesk-email-footer')
    custom_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.project.id, s.id).
      first
    custom_value.value = "##time-now##"
    custom_value.save

    t1 = I18n.l(Time.zone.now)
    email = HelpdeskMailer.
        email_to_supportclient(
            issue,
            {
                :recipient => "owner@example.com",
                :journal   => Journal.find(1),
                :text      => 'text'
            }).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert "text\n\n#{t1}", email.body.to_s
  end
end
