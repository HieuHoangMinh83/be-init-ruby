class UpdateUserPassword < ActiveRecord::Migration[7.1]
  def change
    change_column :users, :password, :string, null: false, default: nil
  end
end
