class RenameContactsToUsers < ActiveRecord::Migration[7.1]
  def change
    rename_table :contacts, :users
  end
end
