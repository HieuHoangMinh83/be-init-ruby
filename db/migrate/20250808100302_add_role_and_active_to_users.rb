class AddRoleAndActiveToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :role, :string
    add_column :users, :rails, :string
  end
end
