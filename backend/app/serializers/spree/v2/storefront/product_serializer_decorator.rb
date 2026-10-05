# frozen_string_literal: true

module Spree
  module V2
    module Storefront
      module ProductSerializerDecorator
        def self.prepended(base)
          base.attribute :price do |product, params|
            params[:user].present? ? base.price(product, params[:currency]) : nil
          end

          base.attribute :display_price do |product, params|
            params[:user].present? ? base.display_price(product, params[:currency]) : nil
          end

          base.attribute :compare_at_price do |product, params|
            params[:user].present? ? base.compare_at_price(product, params[:currency]) : nil
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::ProductSerializer.prepend(Spree::V2::Storefront::ProductSerializerDecorator)
