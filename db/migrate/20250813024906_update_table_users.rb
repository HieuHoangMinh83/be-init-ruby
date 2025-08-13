class UpdateTableUsers < ActiveRecord::Migration[7.1]
  def change
    unless index_exists?(:users, :email, unique: true)
      add_index :users, :email, unique: true
    end
    if column_exists?(:users, :rails)
      remove_column :users, :rails
    end
    add_column :users, :confirm_email, :boolean, default: false, null: false
    add_column :users, :confirm_email_at, :datetime
  end
end
