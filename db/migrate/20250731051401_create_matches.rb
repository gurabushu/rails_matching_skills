class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :target_user, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0

      t.timestamps
    end
    
    add_index :matches, [:user_id, :target_user_id], unique: true
  end
end
