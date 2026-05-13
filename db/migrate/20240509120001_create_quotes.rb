class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.text :text, null: false

      t.timestamps
    end
  end
end
