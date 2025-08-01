class RemoveAvatarFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :avatar, :string
  end
end
