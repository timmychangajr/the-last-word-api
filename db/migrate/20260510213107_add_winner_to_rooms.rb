class AddWinnerToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :winner, :string
  end
end
