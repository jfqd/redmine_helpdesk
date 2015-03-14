module RedmineHelpdesk
  module MailerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :issue_edit,  :helpdesk
      end
    end

    module InstanceMethods
      # Overrides the issue_edit method which is only
      # be called on existing tickets. We will add the
      # owner-email to the recipients only if no email-
      # footer text is available.
      def issue_edit_with_helpdesk(journal, to_users=[], cc_users=[])
        m = issue_edit_without_helpdesk(journal, to_users, cc_users)
        issue = journal.journalized

        other_recipients = []
        # add owner-email to the recipients (list)
        begin
          if journal.send_to_owner == true
            f = CustomField.find_by_name('helpdesk-email-footer')
            p = issue.project
            owner_email = issue.custom_value_for( CustomField.find_by_name('owner-email') ).value
            if !owner_email.blank? && !f.nil? && !p.nil? && p.custom_value_for(f).try(:value).blank?
              other_recipients << owner_email
            end
          end
        rescue Exception => e
          mylogger.error "Error while adding owner-email to recipients of email notification: \"#{e.message}\"."
        end

        if other_recipients.any?
          @users = @users + other_recipients
          mail(
            :to => to_users.map(&:mail),
            :cc => cc_users.map(&:mail),
            :subject => m.subject
          )
        else
          m
        end
      end


      # Sending email notifications to the supportclient
      def email_to_supportclient(issue, recipient, journal=nil, text='')
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id issue
        references issue
        subject = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
        # Set 'from' email-address to 'helpdesk-sender-email' if available.
        # Falls back to regular redmine behaviour if 'sender' is empty.
        p = issue.project
        s = CustomField.find_by_name('helpdesk-sender-email')
        sender = p.custom_value_for(s).try(:value) if p.present? && s.present?
        # If a custom field with text for the first reply is
        # available then use this one instead of the regular
        r = CustomField.find_by_name('helpdesk-first-reply')
        f = CustomField.find_by_name('helpdesk-email-footer')
        reply  = p.nil? || r.nil? ? '' : p.custom_value_for(r).try(:value)
        footer = p.nil? || f.nil? ? '' : p.custom_value_for(f).try(:value)
        # add any attachements
        if journal.present? && text.present?
          journal.details.each do |d|
            if d.property == 'attachment'
              a = Attachment.find(d.prop_key)
              begin
                attachments[a.filename] = File.read(a.diskfile)
              rescue
                # ignore rescue
              end
            end
          end
        end
        if @message_id_object
          headers[:message_id] = "<#{self.class.message_id_for(@message_id_object)}>"
        end
        if @references_objects
          headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o)}>"}.join(' ')
        end
        # create mail object to deliver
        mail = if text.present?
          # sending out the journal note to the support client
          __mail__(
            :from     => sender.present? && sender || Setting.mail_from,
            :reply_to => sender.present? && sender || Setting.mail_from,
            :to       => recipient,
            :subject  => subject,
            :body     => "#{text}\n\n#{footer}".gsub("##issue-id##", issue.id.to_s),
            :date     => Time.zone.now
          )
        elsif reply.present?
          # sending out the first reply message
          __mail__(
            :from     => sender.present? && sender || Setting.mail_from,
            :reply_to => sender.present? && sender || Setting.mail_from,
            :to       => recipient,
            :subject  => subject,
            :body     => "#{reply}\n\n#{footer}".gsub("##issue-id##", issue.id.to_s),
            :date     => Time.zone.now
          )
        else
          # fallback to a regular notifications email with redmine view
          @issue = issue
          @journal = journal
          @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
          __mail__(
            :from     => sender.present? && sender || Setting.mail_from,
            :reply_to => sender.present? && sender || Setting.mail_from,
            :to       => recipient,
            :subject  => subject,
            :date     => Time.zone.now,
            :template_path => 'mailer',
            :template_name => 'issue_edit'
          )
        end
        # return mail object to deliver it
        return mail
      end

      def __mail__(headers={}, &block)
        ActionMailer::Base.instance_method(:mail).bind(self).call(headers, &block)
      end
      private :__mail__
    end # module InstanceMethods
  end # module MailerPatch
end # module RedmineHelpdesk

# Add module to Mailer class
Mailer.send(:include, RedmineHelpdesk::MailerPatch)
