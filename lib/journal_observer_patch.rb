module RedmineHelpdesk
  module JournalObserverPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method_chain :after_create,  :helpdesk
      end
    end

    module InstanceMethods
      # Overrides the after_create method which
      # is only called on journal updates
      def after_create_with_helpdesk(journal)
        if journal.notify? &&
            (Setting.notified_events.include?('issue_updated') ||
              (Setting.notified_events.include?('issue_note_added') && journal.notes.present?) ||
              (Setting.notified_events.include?('issue_status_updated') && journal.new_status.present?) ||
              (Setting.notified_events.include?('issue_priority_updated') && journal.new_value_for('priority_id').present?)
            )
          Mailer.issue_edit(journal).deliver
        end
        # sending email notifications to the supportclient
        # only if the send_to_owner checkbox was checked
        if journal.send_to_owner == true
          issue = journal.journalized.reload
          owner_email = issue.custom_value_for( CustomField.find_by_name('owner-email') ).value
          HelpdeskMailer.email_to_supportclient(issue, owner_email, journal, journal.notes).deliver unless owner_email.blank?
        end
      end
      
    end # module InstanceMethods
  end # module JournalObserverPatch
end # module RedmineHelpdesk

# Add module to Mailer class
JournalObserver.send(:include, RedmineHelpdesk::JournalObserverPatch)
