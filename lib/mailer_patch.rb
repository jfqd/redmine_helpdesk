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
        issue = journal.journalized
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id journal
        references issue
        @author = journal.user
        
        other_recipients = []
        # add owner-email to the recipients
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
        s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
        s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
        s << issue.subject
        @issue = issue
        @users = to_users + cc_users + other_recipients
        @journal = journal
        @journal_details = journal.visible_details(@users.first)
        @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
        mail(
          :to => to_users.map(&:mail),
          :cc => cc_users.map(&:mail),
          :subject => s
        )
      end
      
    end # module InstanceMethods
  end # module MailerPatch
end # module RedmineHelpdesk

# Add module to Mailer class
Mailer.send(:include, RedmineHelpdesk::MailerPatch)
