class CreateCustomFieldCcHandling < ActiveRecord::Migration[5.2]
  def self.up
    c = CustomField.new(
      :name => 'cc-handling',
      :editable => true,
      :visible => true,
      :field_format => 'bool')
    c.type = 'ProjectCustomField' # cannot be set by mass assignement!
    c.save
  end

  def self.down
    CustomField.find_by_name('cc-handling').delete
  end
end
