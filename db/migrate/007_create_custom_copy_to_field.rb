class CreateCustomCopyToField < ActiveRecord::Migration
  def self.up
    c = CustomField.new(
      :name => 'copy-to',
      :editable => true,
      :field_format => 'string')
    c.type = 'IssueCustomField' # cannot be set by mass assignement!
    c.save
    Tracker.all.each do |t|
      execute "INSERT INTO custom_fields_trackers (custom_field_id,tracker_id) VALUES (#{c.id},#{t.id})"
    end
  end

  def self.down
    c = CustomField.find_by_name('copy-to')
    execute "DELETE FROM custom_fields_trackers WHERE custom_field_id=#{c.id}"
    c.delete
  end
end
