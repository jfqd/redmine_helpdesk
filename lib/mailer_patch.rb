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
      def issue_edit_with_helpdesk(journal)
        issue = journal.journalized.reload
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id journal
        references issue
        @author = journal.user
        all_recipients = issue.recipients
        # add owner-email to the recipients
        begin
          if journal.send_to_owner == true
            f = CustomField.find_by_name('helpdesk-email-footer')
            p = issue.project
            owner_email = issue.custom_value_for( CustomField.find_by_name('owner-email') ).value
            if !owner_email.blank? && !f.nil? && !p.nil? && p.custom_value_for(f).try(:value).blank?
              all_recipients << owner_email
            end
          end
        rescue Exception => e
          mylogger.error "Error while adding owner-email to recipients of email notification: \"#{e.message}\"."
        end
        recipients all_recipients
        # Watchers in cc
        cc(issue.watcher_recipients - @recipients)
        s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
        s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
        s << issue.subject
        subject s
        body :issue => issue,
             :journal => journal,
             :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)

        render_multipart('issue_edit', body)
      end
      
      # Sending email notifications to the supportclient
      def email_to_supportclient(issue, sender_email, text='')
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id issue
        recipients sender_email
        subject "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
        # Set 'from' email-address to 'helpdesk-sender-email' if available.
        # Falls back to regular redmine behaviour if 'sender' is empty.
        p = issue.project
        s = CustomField.find_by_name('helpdesk-sender-email')
        if !p.nil? && !s.nil?
          sender = p.custom_value_for(s).try(:value)
          from sender unless sender.blank?
        end
        # If a custom field with text for the first reply is
        # available then use this one instead of the regular
        r = CustomField.find_by_name('helpdesk-first-reply')
        f = CustomField.find_by_name('helpdesk-email-footer')
        reply  = p.nil? || r.nil? ? '' : p.custom_value_for(r).try(:value)
        footer = p.nil? || f.nil? ? '' : p.custom_value_for(f).try(:value)
        if !text.blank?
          content_type "text/plain"
          body "#{text}\n\n#{footer}".gsub("##issue-id##", issue.id.to_s)
        elsif !reply.blank?
          content_type "text/plain"
          body "#{reply}\n\n#{footer}".gsub("##issue-id##", issue.id.to_s)
        else
          body :issue => issue,
               :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)
          render_multipart('issue_add', body)
        end
      end
      
    end # module InstanceMethods
  end # module MailerPatch
end # module RedmineHelpdesk

# Add module to Mailer class
Mailer.send(:include, RedmineHelpdesk::MailerPatch)
