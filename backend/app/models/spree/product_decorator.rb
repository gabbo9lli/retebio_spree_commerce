# frozen_string_literal: true

module Spree
  module ProductDecorator
    def self.prepended(base)
      base.singleton_class.prepend(ClassMethods)
      base.before_save :sync_status_with_activation_date
    end

    module ClassMethods
      # In Retebio, la pubblicazione a catalogo e' determinata dalla data di attivazione (available_on)
      def available(available_on = nil, currency = nil)
        available_on ||= Time.current
        scope = not_discontinued.where("#{Product.quoted_table_name}.available_on IS NOT NULL AND #{Product.quoted_table_name}.available_on <= ?", available_on)

        unless Spree::Config.show_products_without_price
          currency ||= Spree::Store.default.default_currency
          scope = scope.with_currency(currency)
        end

        scope
      end
    end

    def available?
      available_on.present? && available_on <= Time.current && !deleted? && !discontinued?
    end

    private

    def sync_status_with_activation_date
      return if deleted?

      if discontinued?
        self.status = 'archived'
      elsif available_on.present? && available_on <= Time.current
        self.status = 'active'
      else
        self.status = 'draft'
      end
    end
  end
end

Spree::Product.prepend(Spree::ProductDecorator)
