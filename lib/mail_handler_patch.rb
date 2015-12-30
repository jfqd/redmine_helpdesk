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
        roles = issue.author.roles_for_project(issue.project)
        # add owner-email only if the author has assigned some role with
        # permission treat_user_as_supportclient enabled
        if issue.author.type.eql?("AnonymousUser") || roles.any? {|role| role.allowed_to?(:treat_user_as_supportclient) }
          if !@email.reply_to.nil?
            sender_email = @email.reply_to.first
          else
            sender_email = @email.from.first
          end
          email_details = "From: " + @email[:from].formatted.first + "\n"
          email_details << "To: " + @email[:to].formatted.join(', ') + "\n"
          if !@email.reply_to.nil?
            email_details << "Reply-To: " + @email[:reply_to].formatted.join(', ') + "\n"
          end
          if !@email.cc.nil?
            email_details << "Cc: " + @email[:cc].formatted.join(', ') + "\n"
          end
          email_details << "Date: " + @email[:date].to_s + "\n"
          email_details = "<pre>\n" + Mail::Encodings.unquote_and_convert_to(email_details, 'utf-8') + "</pre>"
          issue.description = email_details + issue.description
          issue.save
          custom_field = CustomField.find_by_name('owner-email')
          custom_value = CustomValue.where(
            "customized_id = ? AND custom_field_id = ?", issue.id, custom_field.id).
            first
          custom_value.value = sender_email
          custom_value.save(:validate => false) # skip validation!
          # regular email sending to known users is done
          # on the first issue.save. So we need to send
          # the notification email to the supportclient
          # on our own.
          HelpdeskMailer.email_to_supportclient(issue, sender_email).deliver
        end
        after_dispatch_to_default_hook issue
        return issue
      end

      # let other plugins the chance to override this
      # method to hook into dispatch_to_default
      def after_dispatch_to_default_hook(issue)
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
