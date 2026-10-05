# frozen_string_literal: true

module Spree
  module StoreDecorator
    def name
      super.presence || code.presence || 'Retebio'
    end

    def url
      if Rails.env.development?
        ENV.fetch('SPREE_STORE_URL', 'localhost:4000')
      else
        super
      end
    end
  end
end

Spree::Store.prepend(Spree::StoreDecorator)
