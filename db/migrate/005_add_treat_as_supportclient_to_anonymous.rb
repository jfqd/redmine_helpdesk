class AddTreatAsSupportclientToAnonymous < ActiveRecord::Migration[5.2]
  def self.up
    anon_id = User.where(type: 'AnonymousUser').first.try(:id) ||
              User.where('lastname LIKE ?', 'Anonymous').first.try(:id) ||
              4
    role = Role.where(builtin: anon_id).first
    role.add_permission!(:treat_user_as_supportclient) unless role.nil?
  end

  def self.down
    Role.all.each do |r|
      r.remove_permission!(:treat_user_as_supportclient)
    end
  end
end
