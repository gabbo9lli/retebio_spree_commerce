# frozen_string_literal: true

module Spree
  module V2
    module Storefront
      module VariantSerializerDecorator
        def self.prepended(base)
          base.attribute :price do |variant, params|
            params[:user].present? ? base.price(variant, params[:currency]) : nil
          end

          base.attribute :display_price do |variant, params|
            params[:user].present? ? base.display_price(variant, params[:currency]) : nil
          end

          base.attribute :compare_at_price do |variant, params|
            params[:user].present? ? base.compare_at_price(variant, params[:currency]) : nil
          end

          base.attribute :weight do |variant|
            variant.weight.to_f
          end

          base.attribute :quantity_step do |variant|
            (variant.weight.present? && variant.weight > 0) ? variant.weight.to_f : 1.0
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::VariantSerializer.prepend(Spree::V2::Storefront::VariantSerializerDecorator)
