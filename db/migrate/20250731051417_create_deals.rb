class CreateDeals < ActiveRecord::Migration[8.0]
  def change
    create_table :deals do |t|
      t.references :match, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :freelancer, null: false, foreign_key: { to_table: :users }
      t.string :title
      t.text :description
      t.integer :status, default: 0
      t.integer :price
      t.datetime :deadline

      t.timestamps
    end
  end
end
