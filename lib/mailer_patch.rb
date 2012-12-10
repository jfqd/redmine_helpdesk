module RedmineHelpdesk
  module MailerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
    end
    
    module InstanceMethods
      # sending email notifications to the supportclient
      def email_to_supportclient(issue, sender_email, text='')
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id issue
        recipients sender_email
        subject "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
        # If a custom field with text for the first reply is
        # available then use this one instead of the regular
        r = CustomField.find_by_name('helpdesk-first-reply')
        f = CustomField.find_by_name('helpdesk-email-footer')
        p = issue.project
        reply  = p.nil? || r.nil? ? '' : p.custom_value_for(r).try(:value)
        footer = p.nil? || f.nil? ? '' : p.custom_value_for(f).try(:value)
        if !text.blank?
          content_type "text/plain"
          body "#{text}\n\n#{footer}".gsub("##issue-id##", issue.id.to_s)
        elsif reply.blank?
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
