class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.string :fullName
      t.string :email
      t.integer :age
      t.boolean :active, null: false, default: false
      t.timestamps
    end
  end
end
