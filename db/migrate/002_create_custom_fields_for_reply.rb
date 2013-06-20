class CreateCustomFieldsForReply < ActiveRecord::Migration
  def self.up
    c = CustomField.new(
      :name => 'helpdesk-first-reply',
      :editable => true,
      :visible => false,          # do not show it on the project summary page
      :field_format => 'text')
    c.type = 'ProjectCustomField' # cannot be set by mass assignement!
    c.save
    d = CustomField.new(
      :name => 'helpdesk-email-footer',
      :editable => true,
      :visible => false,          # do not show it on the project summary page
      :field_format => 'text')
    d.type = 'ProjectCustomField' # cannot be set by mass assignement!
    d.save
  end

  def self.down
    CustomField.find_by_name('helpdesk-first-reply').delete
    CustomField.find_by_name('helpdesk-email-footer').delete
  end
end