module RedmineHelpdesk
  module JournalPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :send_notification,  :helpdesk
      end
    end

    module InstanceMethods
      # Overrides the send_notification method which
      # is only called on journal updates
      def send_notification_with_helpdesk()
        send_notification_without_helpdesk

        # sending email notifications to the supportclient
        # only if the send_to_owner checkbox was checked
        if send_to_owner == true && notes.length != 0
          issue = journalized.reload
          owner_email = issue.custom_value_for( CustomField.find_by_name('owner-email') ).value
          Mailer.email_to_supportclient(issue, owner_email, self, notes).deliver unless owner_email.blank?
        end
      end

    end # module InstanceMethods
  end # module JournalPatch
end # module RedmineHelpdesk

# Add module to Journal class
Journal.send(:include, RedmineHelpdesk::JournalPatch)
