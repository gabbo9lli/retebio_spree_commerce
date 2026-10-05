# frozen_string_literal: true

module Spree
  module AdminUserDecorator
    def self.prepended(base)
      base.class_eval do
        def has_spree_role?(role_name, resource = nil)
          resource ||= Spree::Store.current
          role_users.where(resource: [resource, nil]).joins(:role).where(Spree::Role.table_name => { name: role_name }).exists?
        end

        def spree_admin?(resource = nil)
          resource ||= Spree::Store.current
          has_spree_role?(Spree::Role::ADMIN_ROLE, resource) || spree_roles.where(name: Spree::Role::ADMIN_ROLE).exists?
        end
      end
    end
  end
end

Spree::AdminUser.prepend(Spree::AdminUserDecorator)
