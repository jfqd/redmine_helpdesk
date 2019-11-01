class CreateCustomFieldForReplySeparator < ActiveRecord::Migration[5.2]
  def self.up
    begin
      c = CustomField.new(
        :name => 'helpdesk-reply-separator',
        :editable => true,
        :visible => false,          # do not show it on the project summary page
        :field_format => 'string',
        :default_value => '-- Reply above this line --')
      c.type = 'ProjectCustomField'
      c.save
    rescue
      # rescue a possible migration error caused by renumbering the file
    end
  end

  def self.down
    CustomField.find_by_name('helpdesk-reply-separator').delete
  end
end