class CreateCustomFieldForReplySeparator < ActiveRecord::Migration
  def self.up
    c = CustomField.new(
      :name => 'helpdesk-reply-separator',
      :editable => true,
      :visible => false,          # do not show it on the project summary page
      :field_format => 'string',
      :default_value => '--Reply above this line--')
    c.type = 'ProjectCustomField'
    c.save
  end

  def self.down
    CustomField.find_by_name('helpdesk-reply-separator').delete
  end
end

