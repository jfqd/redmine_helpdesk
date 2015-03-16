class AppendFooterToFirstReply < ActiveRecord::Migration

  # Appends helpdesk-email-footer to helpdesk-first-reply to ensure backward
  # compatibility for updaters. See https://github.com/jfqd/redmine_helpdesk/issues/52
  def self.up
    first_reply_cf_id = CustomField.find_by_name('helpdesk-first-reply').id
    footer_cf_id = CustomField.find_by_name('helpdesk-email-footer').id

    CustomValue.where(:custom_field_id => first_reply_cf_id).each do |first_reply_cv|
      if !first_reply_cv.value.nil?
        first_reply_with_footer = first_reply_cv.value
        first_reply_with_footer << "\n\n"
        first_reply_with_footer << CustomValue.where("custom_field_id=? and customized_id=?", footer_cf_id, first_reply_cv.customized_id).first.value

        CustomValue.update(first_reply_cv.id, :value => first_reply_with_footer)
      end
    end
  end

end
