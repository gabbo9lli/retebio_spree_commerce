# frozen_string_literal: true

module Spree
  module LineItemDecorator
    def self.prepended(base)
      base.validate :validate_quantity_matches_weight_step
    end

    private

    def validate_quantity_matches_weight_step
      return unless variant&.weight.present? && variant.weight > 0
      step = variant.weight.to_i
      return if step <= 1

      if (quantity % step) != 0
        errors.add(:quantity, "deve essere un multiplo del peso di vendita (#{step})")
      end
    end
  end
end

Spree::LineItem.prepend(Spree::LineItemDecorator)
