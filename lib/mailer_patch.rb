module RedmineHelpdesk
  module MailerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method_chain :issue_edit,  :helpdesk
      end
    end

    module InstanceMethods
      # Overrides the issue_edit method, this method
      # is only called on existing tickets
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
            owner_email = issue.custom_value_for( CustomField.find_by_name('owner-email') ).value
            all_recipients << owner_email unless owner_email.blank?
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
      
      def email_to_supportclient(issue, sender_email)
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id issue
        recipients [sender_email]
        subject "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
        body :issue => issue,
             :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)
        render_multipart('issue_add', body)
      end
      
    end # module InstanceMethods
  end # module MailerPatch
end # module RedmineHelpdesk

# Add module to Mailer class
Mailer.send(:include, RedmineHelpdesk::MailerPatch)
