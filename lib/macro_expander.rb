module MacroExpander
  def expand_macros(string, issue, journal)
    e = Expander.new(string, issue, journal)
    e.expand
  end

  class Expander
    include Redmine::I18n

    def initialize(string, issue, journal)
      @string = string
      @issue = issue
      @journal = journal
    end

    def expand
      unless @issue.nil?
        expand_issue
        expand_project
      end
      expand_user unless @journal.nil?
      expand_base

      @string
    end

    private

    def expand_issue
      @string.gsub!("##issue-id##", @issue.id.to_s)
      @string.gsub!("##issue-subject##", @issue.subject)
      @string.gsub!("##issue-tracker##", @issue.tracker.name)
      @string.gsub!("##issue-status##", @issue.status.name)
    end

    def expand_project
      p = @issue.project
      @string.gsub!("##project-name##", p.name)
    end

    def expand_user
      u = @journal.user
      @string.gsub!("##user-name##", u.name)
      @string.gsub!("##user-firstname##", u.firstname)
      @string.gsub!("##user-lastname##", u.lastname)
      @string.gsub!("##user-mail##", u.mail)
      @string.gsub!("##user-login##", u.login)
      expand_user_cf(u)
    end

    def expand_user_cf(user)
      CustomField.where(
        "type = 'UserCustomField'").each do |user_cf|
        cf_name = user_cf.name.downcase.gsub(' ', '-')
        user_cf_cv = user.custom_value_for(user_cf).try(:value)
        @string.gsub!("##user-cf-#{cf_name}##", user_cf_cv) unless user_cf_cv.nil?
      end
    end

    def expand_base
      @string.gsub!("##time-now##", I18n.l(Time.zone.now))
    end
  end
end
