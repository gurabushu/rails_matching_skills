class AddHobbiesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :hobbies, :text
  end
end
