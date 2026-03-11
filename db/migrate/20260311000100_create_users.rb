class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :phone, null: false
      t.string :password_digest, null: false
      t.string :name
      t.string :status, null: false, default: "active"
      t.datetime :last_sign_in_at
      t.string :last_sign_in_ip

      t.timestamps
    end

    add_index :users, :phone, unique: true
    add_index :users, :status
  end
end
