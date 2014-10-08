class AddTreatAsSupportclientToAnonymous < ActiveRecord::Migration
  def self.up
    Role.find(2).add_permission!(:treat_user_as_supportclient)
  end

  def self.down
    Role.find(:all).each do |r|
      r.remove_permission!(:treat_user_as_supportclient)
    end
  end
end
