module RedmineHelpdesk
  module MailHandlerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method :dispatch_to_default_without_helpdesk, :dispatch_to_default
        alias_method :dispatch_to_default, :dispatch_to_default_with_helpdesk

        alias_method :receive_issue_reply_without_helpdesk, :receive_issue_reply
        alias_method :receive_issue_reply, :receive_issue_reply_with_helpdesk
      end
    end

    module InstanceMethods
      private
      # Overrides the dispatch_to_default method to
      # set the owner-email of a new issue created by
      # an email request
      def dispatch_to_default_with_helpdesk
        issue = receive_issue
        roles = if issue.author.class == AnonymousUser
          Role.where(builtin: issue.author.id)
        else
          issue.author.roles_for_project(issue.project)
        end
        # add owner-email only if the author has assigned some role with
        # permission treat_user_as_supportclient enabled
        if issue.author.type.eql?("AnonymousUser") || roles.any? {|role| role.allowed_to?(:treat_user_as_supportclient) }
          sender_email = @email.from.first
          email_details = "From: " + @email[:from].formatted.first + "\n"
          email_details << "To: " + @email[:to].formatted.join(', ') + "\n"

          # any cc handling needed?
          custom_field = CustomField.find_by_name('cc-handling')
          custom_value = CustomValue.where(
            "customized_id = ? AND custom_field_id = ?", issue.project.id, custom_field.id
          ).first
          if (!@email.cc.nil?) && (custom_value.value == '1')
            carbon_copy = @email[:cc].formatted.join(', ')
            email_details << "Cc: " + carbon_copy + "\n"
            custom_field = CustomField.find_by_name('copy-to')
            custom_value = CustomValue.where(
              "customized_id = ? AND custom_field_id = ?", issue.id, custom_field.id
            ).first
            custom_value.value = carbon_copy
            custom_value.save(:validate => false)
          else
            carbon_copy = nil
          end

          email_details << "Date: " + @email[:date].to_s + "\n"
          email_details = "<pre>\n" + Mail::Encodings.unquote_and_convert_to(email_details, 'utf-8') + "</pre>"
          issue.description = email_details + issue.description
          issue.save
          custom_field = CustomField.find_by_name('owner-email')
          custom_value = CustomValue.where(
            "customized_id = ? AND custom_field_id = ?", issue.id, custom_field.id
          ).first

          if custom_value.value.to_s.strip.empty?
            custom_value.value = sender_email
            custom_value.save(:validate => false) # skip validation!
          else
            # Email owner field was already set by some preprocess hooks.
            # So now we need to send message to another recepient.
            sender_email = custom_value.value.to_s.strip
          end
          
          # regular email sending to known users is done
          # on the first issue.save. So we need to send
          # the notification email to the supportclient
          # on our own.
          HelpdeskMailer.email_to_supportclient(
            issue, {
              :recipient => sender_email,
              :carbon_copy => carbon_copy
            }
          ).deliver
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

      # reopening an closed issues by email
      def receive_issue_reply_with_helpdesk(issue_id, from_journal=nil)
        issue = Issue.find_by_id(issue_id)
        if issue.present?
          custom_field = CustomField.find_by_name('reopen-closed-issues-by-email')
          custom_value = CustomValue.where(
            "customized_id = ? AND custom_field_id = ?", issue.project.id, custom_field.id
          ).first
          if issue.closed? && custom_value.value.present?
            status_id = IssueStatus.where("name = ?", custom_value.value).first.try(:id)
            unless status_id.nil?
              issue.status_id = status_id
              issue.save
            end
          end
        end
        # return to regular method
        receive_issue_reply_without_helpdesk(issue_id, from_journal=nil)
      end

    end # module InstanceMethods
  end # module MailHandlerPatch
end # module RedmineHelpdesk

# Add module to MailHandler class
MailHandler.send(:include, RedmineHelpdesk::MailHandlerPatch)
