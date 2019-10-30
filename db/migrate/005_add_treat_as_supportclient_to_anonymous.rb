class AddTreatAsSupportclientToAnonymous < ActiveRecord::Migration[5.2]
  def self.up
    anon = User.where(lastname: 'Anonymous').first
    Role.where(builtin: anon.id).add_permission!(:treat_user_as_supportclient)
  end

  def self.down
    Role.find(:all).each do |r|
      r.remove_permission!(:treat_user_as_supportclient)
    end
  end
end
