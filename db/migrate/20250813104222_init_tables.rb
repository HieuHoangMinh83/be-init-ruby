class InitTables < ActiveRecord::Migration[7.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid do |t|
      t.string :fullName
      t.string :email, null: false
      t.integer :age
      t.boolean :active, default: false, null: false
      t.string :password, null: false
      t.string :refresh_token
      t.string :role
      t.boolean :confirm_email, default: false, null: false
      t.datetime :confirm_email_at
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :user_settings, id: :uuid do |t|
      t.string :theme, null: false, default: "light"
      t.boolean :notifications_enabled, null: false, default: true
      t.string :language, null: false, default: "vi"
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.timestamps
    end

    create_table :projects, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.references :owner, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.timestamps
    end

    create_table :tasks, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "pending"
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end

    create_table :tags, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :tasks_tags, id: :uuid do |t|
      t.references :task, null: false, foreign_key: { to_table: :tasks }, type: :uuid
      t.references :tag, null: false, foreign_key: { to_table: :tags }, type: :uuid
      t.timestamps
    end
  end
end
