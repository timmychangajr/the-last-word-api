class CreateRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :rooms do |t|
      t.string :code, null: false
      t.jsonb :buffer_array, default: [], null: false
      t.string :target_quote, null: false
      t.integer :timer, default: 300 # 5 minutes in seconds

      t.timestamps
    end
    add_index :rooms, :code, unique: true
  end
end
