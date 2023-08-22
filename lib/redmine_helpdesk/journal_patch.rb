module RedmineHelpdesk
  module JournalPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method :send_notification_without_helpdesk, :send_notification
        alias_method :send_notification, :send_notification_with_helpdesk
      end
    end

    module InstanceMethods
      # Overrides the send_notification method which
      # is only called on journal updates
      def send_notification_with_helpdesk
        if notify? && (Setting.notified_events.include?('issue_updated') ||
            (Setting.notified_events.include?('issue_note_added') && notes.present?) ||
            (Setting.notified_events.include?('issue_status_updated') && new_status.present?) ||
            (Setting.notified_events.include?('issue_assigned_to_updated') && detail_for_attribute('assigned_to_id').present?) ||
            (Setting.notified_events.include?('issue_priority_updated') && new_value_for('priority_id').present?)
          )
          Mailer.deliver_issue_edit(self)
        end
        # do not send on private-notes
        if private_notes == true && send_to_owner == true 
          self.send_to_owner = false
          self.save( validate: false )
        end
        # sending email notifications to the supportclient
        # only if the send_to_owner checkbox was checked
        if send_to_owner == true && notes.length != 0
          issue = self.journalized.reload
          owner_email = issue.custom_value_for( CustomField.find_by_name('owner-email') ).value
          HelpdeskMailer.email_to_supportclient(
            issue, {
              recipient: owner_email,
              journal:   self,
              text:      notes
            }
          ).deliver unless owner_email.blank?
        end
      end
      
    end # module InstanceMethods
  end # module JournalPatch
end # module RedmineHelpdesk

# Add module to Journal class
Journal.send(:include, ::RedmineHelpdesk::JournalPatch)
