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
        redmine_headers 'Issue-Assignee' => issue.
            assigned_to.login if issue.assigned_to
        message_id issue
        references issue

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
        # create mail object to deliver

        @issue = issue
        @journal = journal
        @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)

        __mail__(
          helpdesk_headers(issue, recipient, text)
        )
      end

      private

      def helpdesk_headers(issue, recipient, text)
        from = helpdesk_from(issue)
        reply = helpdesk_reply(issue)
        if text.present?
          # sending out the journal note to the support client
          body = "#{text}\n\n#{helpdesk_footer(issue)}"
        elsif reply.present?
          # sending out the first reply message
          body = "#{reply}\n\n#{helpdesk_footer(issue)}"
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
        p = issue.project
        s = CustomField.find_by_name('helpdesk-sender-email')
        sender = p.custom_value_for(s).try(:value) if p.present? && s.present?

        sender.present? && sender || Setting.mail_from
      end

      def helpdesk_reply(issue)
        p = issue.project
        r = CustomField.find_by_name('helpdesk-first-reply')
        p.nil? || r.nil? ? '' : p.custom_value_for(r).try(:value)
      end

      def helpdesk_footer(issue)
        p = issue.project
        f = CustomField.find_by_name('helpdesk-email-footer')
        p.nil? || f.nil? ? '' : p.custom_value_for(f).try(:value)
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
