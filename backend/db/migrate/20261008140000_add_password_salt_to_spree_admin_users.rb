# frozen_string_literal: true

class AddPasswordSaltToSpreeAdminUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_admin_users, :password_salt, :string, limit: 128 unless column_exists?(:spree_admin_users, :password_salt)
  end
end
