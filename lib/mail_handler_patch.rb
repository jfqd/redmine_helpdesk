module RedmineHelpdesk
  module MailHandlerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method_chain :dispatch_to_default, :helpdesk
      end
    end
    
    module InstanceMethods
      private
      # Overrides the dispatch_to_default method to
      # set the owner-email of a new issue created by
      # an email request
      def dispatch_to_default_with_helpdesk
        issue = receive_issue
        # add owner-email only if the email is comming from an AnonymousUser
        if issue.author.class == AnonymousUser
          sender_email = @email.from.to_a.first.to_s.strip
          custom_field = CustomField.find_by_name('owner-email')
          custom_value = CustomValue.find(
            :first,
            :conditions => ["customized_id = ? AND custom_field_id = ?", issue.id, custom_field.id]
          )
          custom_value.value = sender_email
          custom_value.save(false) # skip validation!
          # regular email sending to known users is done
          # on the first issue.save. So we need to send
          # the notification email to the supportclient
          # on our own.
          HelpdeskMailer.email_to_supportclient(issue, sender_email).deliver
        end
        issue
      end
      
      # Fix an issue with email.has_attachments?
      def add_attachments(obj)
         if !email.attachments.nil? && email.attachments.size > 0
           email.attachments.each do |attachment|
             obj.attachments << Attachment.create(:container => obj,
                               :file => attachment.decoded,
                               :filename => attachment.filename,
                               :author => user,
                               :content_type => attachment.mime_type)
          end
        end
      end
      
      
    end # module InstanceMethods
  end # module MailHandlerPatch
end # module RedmineHelpdesk

# Add module to MailHandler class
MailHandler.send(:include, RedmineHelpdesk::MailHandlerPatch)
