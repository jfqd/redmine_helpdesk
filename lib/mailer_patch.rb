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

        other_recipients = helpdesk_other_recipients(journal)

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
        redmine_headers 'Issue-Assignee' => issue.
            assigned_to.login if issue.assigned_to
        message_id issue
        references issue

        # add any attachements
        helpdesk_add_attachments(journal) if text.present?

        # create mail object to deliver
        @issue = issue
        @journal = journal
        @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)

        __mail__(
          helpdesk_headers(issue, recipient, text)
        )
      end

      private

      def helpdesk_other_recipients(journal)
        other_recipients = []
        begin
          if journal.send_to_owner == true
            issue = journal.journalized
            p = issue.project
            owner_email = helpdesk_customvalue(issue, 'owner-email')
            if !owner_email.blank? && !helpdesk_customvalue(p, 'helpdesk-email-footer').blank?
              other_recipients << owner_email
            end
          end
        rescue Exception => e
          mylogger.error "Error while adding owner-email to recipients of email notification: \"#{e.message}\"."
        end
        other_recipients
      end

      def helpdesk_headers(issue, recipient, text)
        p = issue.project
        from = helpdesk_from(issue)
        reply = helpdesk_customvalue(p, 'helpdesk-first-reply')
        footer = helpdesk_customvalue(p, 'helpdesk-email-footer')
        if text.present?
          # sending out the journal note to the support client
          body = "#{text}\n\n#{footer}"
        elsif reply.present?
          # sending out the first reply message
          body = "#{reply}\n\n#{footer}"
        end

        h = {
          :from     => from,
          :reply_to => from,
          :to       => recipient,
          :subject  => helpdesk_subject(issue),
          :date     => Time.zone.now
        }

        if body.empty?
          h[:template_path] = 'mailer'
          h[:template_name] = 'issue_edit'
        else
          h[:body] = body.gsub("##issue-id##", issue.id.to_s)
        end
        h
      end

      def helpdesk_subject(issue)
        "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
      end

      def helpdesk_from(issue)
        # Set 'from' email-address to 'helpdesk-sender-email' if available.
        # Falls back to regular redmine behaviour if 'sender' is empty.
        sender = helpdesk_customvalue(issue.project, 'helpdesk-sender-email')
        sender.present? && sender || Setting.mail_from
      end

      def helpdesk_customvalue(o, name)
        v = CustomField.find_by_name(name)
        o.nil? || v.nil? ? '' : o.custom_value_for(v).try(:value)
      end

      def helpdesk_add_attachments(journal)
        if journal.present?
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
      end

      def __mail__(headers)
        if @message_id_object
          headers[:message_id] = "<#{self.class.message_id_for(@message_id_object)}>"
        end
        if @references_objects
          headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o)}>"}.join(' ')
        end

        ActionMailer::Base.instance_method(:mail).bind(self).call(headers)
      end
    end # module InstanceMethods
  end # module MailerPatch
end # module RedmineHelpdesk

# Add module to Mailer class
Mailer.send(:include, RedmineHelpdesk::MailerPatch)
