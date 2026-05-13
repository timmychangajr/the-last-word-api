class AddTotalIndicesToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :total_indices, :integer, default: 0, null: false
  end
end
