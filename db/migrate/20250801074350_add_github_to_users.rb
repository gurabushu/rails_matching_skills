class AddGithubToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :github, :string
  end
end
