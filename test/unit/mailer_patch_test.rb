require File.dirname(__FILE__) + '/../test_helper'

class MailerPatchTest < ActionMailer::TestCase
  include Redmine::I18n

  self.use_transactional_fixtures = true

  fixtures :projects, :projects_trackers,
           :issues, :issue_statuses, :trackers,
           :journals, :journal_details,
           :attachments,
           :members, :member_roles,
           :roles,
           :users,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers

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

  def test_email_headers
    issue = Issue.find(1)
    email = Mailer.
        email_to_supportclient(issue, "owner@example.com").
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_not_nil email
    assert_equal issue.project.identifier, email.header['X-Redmine-Project'].to_s
    assert_equal issue.id, email.header['X-Redmine-Issue-Id'].to_s.to_i
    assert_equal issue.author.login, email.header['X-Redmine-Issue-Author'].to_s
    assert_equal issue.assigned_to.login, email.header['X-Redmine-Issue-Assignee'].to_s

    #assert_equal 'OOF', email.header['X-Auto-Response-Suppress'].to_s
    #assert_equal 'auto-generated', email.header['Auto-Submitted'].to_s
    #assert_equal '<redmine.example.net>', email.header['List-Id'].to_s
  end

  def test_email_default_sender
    issue = Issue.find(1)
    s = CustomField.find_by_name('helpdesk-sender-email')
    custom_value = CustomValue.find(
      :first,
      :conditions => ["customized_id = ? AND custom_field_id = ?", issue.project.id, s.id]
    )
    custom_value.destroy

    email = Mailer.
        email_to_supportclient(issue, "owner@example.com").
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal Setting.mail_from, email.header['From'].to_s
  end

  def test_email_helpdesk_sender
    issue = Issue.find(1)
    email = Mailer.
        email_to_supportclient(issue, "owner@example.com").
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal "reply@example.com", email.header['From'].to_s
  end

  def test_email_helpdesk_sender_with_phrase
    issue = Issue.find(1)
    s = CustomField.find_by_name('helpdesk-sender-email')
    custom_value = CustomValue.find(
      :first,
      :conditions => ["customized_id = ? AND custom_field_id = ?", issue.project.id, s.id]
    )
    custom_value.value = "Redmine helpdesk <reply@example.com>"
    custom_value.save

    email = Mailer.
        email_to_supportclient(issue, "owner@example.com").
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal "Redmine helpdesk <reply@example.com>", email.header['From'].to_s
  end

  def test_first_reply
    issue = Issue.find(1)
    email = Mailer.
        email_to_supportclient(issue, "owner@example.com").
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_match /^redmine\.issue-1\.\d+\.[a-f0-9]+@example\.net/, email.message_id
    assert_match /redmine\.issue-1\.\d+@example\.net/, email.references

    assert_equal "first reply\n\nemail footer",
        email.body.to_s
  end

  def test_edit
    issue = Issue.find(1)
    email = Mailer.
        email_to_supportclient(
            issue,
            "owner@example.com",
            Journal.find(1),
            'text').
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_match /^redmine\.issue-1\.\d+\.[a-f0-9]+@example\.net/, email.message_id
    assert_match /redmine\.issue-1\.\d+@example\.net/, email.references

    assert_equal "text\n\nemail footer",
        email.body.to_s
  end

  def test_fallback_message_id
    issue = Issue.find(2)
    s = CustomField.find_by_name('helpdesk-first-reply')
    custom_value = CustomValue.find(
      :first,
      :conditions => ["customized_id = ? AND custom_field_id = ?", issue.project.id, s.id]
    )
    custom_value.destroy

    email = Mailer.
        email_to_supportclient(
            issue,
            "owner@example.com",
            Journal.find(1),
            'text').
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_match /^redmine\.issue-2\.\d+\.[a-f0-9]+@example\.net/, email.message_id
    assert_match /redmine\.issue-2\.\d+@example\.net/, email.references
  end

  def test_subject
    issue = Issue.find(1)
    email = Mailer.
        email_to_supportclient(issue, "owner_email").
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}",
        email.subject.to_s
  end

  # Test with single attachment and verify against fixture file
  def test_attachments_added
    Attachment.storage_path = File.dirname(__FILE__) + '/../fixtures/files'
    issue = Issue.find(1)
    email = Mailer.
        email_to_supportclient(
            issue,
            "owner@example.com",
            Journal.find(3),
            'text').
        deliver
    assert !ActionMailer::Base.deliveries.empty?
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    attachments_length = mail.attachments.length
    assert_equal 1, attachments_length
    filename = mail.attachments[0].filename
    assert_equal "source.rb", filename
    content = mail.attachments[0].body.to_s
    original_content = File.open(
        Attachment.find(
            Journal.find(3).details.first.prop_key).diskfile).read
    assert_equal original_content, content
  end
end
