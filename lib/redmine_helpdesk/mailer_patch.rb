module RedmineHelpdesk
  module MailerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method :issue_edit_without_helpdesk, :issue_edit
        alias_method :issue_edit, :issue_edit_with_helpdesk
      end
    end

    module InstanceMethods
      # Overrides the issue_edit method which is only
      # be called on existing tickets. We will add the
      # owner-email to the recipients only if no email-
      # footer text is available.
      def issue_edit_with_helpdesk(user, journal)
        issue = journal.journalized
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login,
                        'Issue-Tracker' => issue.tracker
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id journal
        references issue
        @author = journal.user

        # process reply-separator
        f = CustomField.find_by_name('helpdesk-reply-separator')
        reply_separator = issue.project.custom_value_for(f).try(:value)
        if !reply_separator.blank? and !journal.notes.nil?
          journal.notes = journal.notes.gsub(/#{reply_separator}.*/m, '')
          journal.save(:validate => false)
        end

        # add owner-email to the recipients
        alternative_user = nil
        begin
          if journal.send_to_owner == true
            f = CustomField.find_by_name('helpdesk-email-footer')
            p = issue.project
            owner_email = issue.custom_value_for( CustomField.find_by_name('owner-email') ).value
            if !owner_email.blank? && !f.nil? && !p.nil? && p.custom_value_for(f).try(:value).blank?
              alternative_user = owner_email
            end
          end
        rescue Exception => e
          Rails.logger.error "Error while adding owner-email to recipients of email notification: \"#{e.message}\"."
        end

        # any cc handling needed?
        cc_users = nil
        begin
          # any cc handling needed?
          if alternative_user.present?
            custom_field = CustomField.find_by_name('cc-handling')
            custom_value = CustomValue.where(
              "customized_id = ? AND custom_field_id = ?", issue.project.id, custom_field.id
            ).first
            cc_users = custom_value.value.split(',').map(&:strip) if custom_value.value.present?
          end
        rescue Exception => e
          Rails.logger.error "Error while adding cc-users to recipients of email notification: \"#{e.message}\"."
        end

        s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
        s += "(#{issue.status.name}) " if journal.new_value_for('status_id') && Setting.show_status_changes_in_mail_subject?
        s += issue.subject
        u = (alternative_user.present? ? alternative_user : user)
        @issue = issue
        @user = u
        @journal = journal
        @journal_details = journal.visible_details
        @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
        mail(
          :to => u,
          :cc => cc_users,
          :subject => s
        )
      end
      
    end # module InstanceMethods
  end # module MailerPatch
end # module RedmineHelpdesk

# Add module to Mailer class
Mailer.send(:include, ::RedmineHelpdesk::MailerPatch)
