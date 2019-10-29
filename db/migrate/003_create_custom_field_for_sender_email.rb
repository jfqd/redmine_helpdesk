class CreateCustomFieldForSenderEmail < ActiveRecord::Migration[5.2]
  def self.up
    c = CustomField.new(
      :name => 'helpdesk-sender-email',
      :editable => true,
      :visible => true,
      :field_format => 'string')
    c.type = 'ProjectCustomField' # cannot be set by mass assignement!
    c.save
  end

  def self.down
    CustomField.find_by_name('helpdesk-sender-email').delete
  end
end