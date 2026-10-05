# frozen_string_literal: true

module Spree
  module Api
    module V2
      module Storefront
        module CartControllerDecorator
          def self.prepended(base)
            base.prepend_before_action :require_spree_user_for_b2b, only: [:create, :add_item, :set_quantity, :remove_line_item]
          end

          private

          def require_spree_user_for_b2b
            unless spree_current_user.present?
              render_error_payload(Spree.t(:b2b_login_required, default: 'Accesso richiesto per acquistare'), :unauthorized)
            end
          end
        end
      end
    end
  end
end

Spree::Api::V2::Storefront::CartController.prepend(Spree::Api::V2::Storefront::CartControllerDecorator)
