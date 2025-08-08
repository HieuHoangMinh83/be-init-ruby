class UpdateContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :active, :boolean, default: false, null: false
  end
end
