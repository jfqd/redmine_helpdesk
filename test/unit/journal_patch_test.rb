require File.dirname(__FILE__) + '/../test_helper'

class JournalPatchTest < ActiveSupport::TestCase
  include Redmine::I18n

  self.use_transactional_fixtures = true

  fixtures :all

  def setup
    User.current = User.find(1)
  end

  def teardown
    Setting.clear_cache
  end

  def test_notification_not_sent_when_send_to_owner_false
    HelpdeskMailer.any_instance.expects(:email_to_supportclient).never
    Mailer.any_instance.stubs(:deliver_issue_edit).returns(true)

    issue = Issue.find(1)
    journal = issue.journals.first
    journal.send_to_owner = false
    journal.save!

    journal.send(:send_notification)
  end

  def test_notification_not_sent_when_notes_length_zero
    HelpdeskMailer.any_instance.expects(:email_to_supportclient).never
    Mailer.any_instance.stubs(:deliver_issue_edit).returns(true)

    issue = Issue.find(1)
    journal = issue.journals.first
    journal.notes = ""
    journal.send_to_owner = true
    journal.save!

    journal.send(:send_notification)
  end

  def test_notification_note_sent_when_owner_email_blank
    HelpdeskMailer.any_instance.expects(:email_to_supportclient).never
    Mailer.any_instance.stubs(:deliver_issue_edit).returns(true)

    issue = Issue.find(1)
    journal = issue.journals.first
    owner_field = CustomField.find_by_name('owner-email')
    owner_value = CustomValue.where(
      "customized_id = ? AND custom_field_id = ?", issue.id, owner_field.id).
      first
    owner_value.value = ""
    owner_value.save!
    journal.send_to_owner = true
    journal.save!

    journal.send(:send_notification)
  end

  def test_notification_sent
    Mailer.any_instance.stubs(:deliver_issue_edit).returns(true)

    issue = Issue.find(1)
    journal = issue.journals.first
    journal.send_to_owner = true
    journal.save!

    HelpdeskMailer.any_instance.expects(:email_to_supportclient).with(issue, 
        {:recipient => "owner@example.com", 
         :journal   => journal, 
         :text      => journal.notes
        }).once
    journal.send(:send_notification)
  end
end
