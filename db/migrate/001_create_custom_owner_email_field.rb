class CreateCustomOwnerEmailField < ActiveRecord::Migration
  def self.up
    # fix PG:DuplicateColumn errors
    # https://github.com/jfqd/redmine_helpdesk/issues/66
    unless column_exists? :journals, :send_to_owner
      add_column :journals, :send_to_owner, :boolean, :default => false
      c = CustomField.new(
        :name => 'owner-email',
        :editable => true,
        :field_format => 'string')
      c.type = 'IssueCustomField' # cannot be set by mass assignement!
      c.save
      Tracker.all.each do |t|
        execute "INSERT INTO custom_fields_trackers (custom_field_id,tracker_id) VALUES (#{c.id},#{t.id})"
      end
    end
  end

  def self.down
    c = CustomField.find_by_name('owner-email')
    execute "DELETE FROM custom_fields_trackers WHERE custom_field_id=#{c.id}"
    c.delete
    remove_column :journals, :send_to_owner
  end
end
