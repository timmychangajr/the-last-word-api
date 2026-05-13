class AddUsersToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :users, :jsonb
  end
end
