# frozen_string_literal: true

module Spree
  module StoreDecorator
    def name
      super.presence || code.presence || 'Retebio'
    end

    def url
      store_url = ENV['SPREE_STORE_URL']
      if store_url.present? && !store_url.match?(/\A\d+\.\d+\.\d+\.\d+\z/)
        store_url
      elsif ENV['API_DOMAIN'].present?
        ENV['API_DOMAIN']
      elsif Rails.env.development?
        'localhost:4000'
      else
        super
      end
    end

    def formatted_url
      return if url.blank?
      return url if url.start_with?('http://', 'https://')

      protocol = (Rails.env.production? || ENV['FORCE_SSL'] == 'true' || ENV['ASSUME_SSL'] == 'true') ? 'https://' : 'http://'
      "#{protocol}#{url}"
    end
  end
end

Spree::Store.prepend(Spree::StoreDecorator)
