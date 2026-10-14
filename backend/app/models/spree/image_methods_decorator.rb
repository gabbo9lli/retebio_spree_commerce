# frozen_string_literal: true

module Spree
  module ImageMethodsDecorator
    def generate_url(size:, gravity: 'centre', quality: 80, background: [255, 255, 255])
      return if size.blank?

      size = size.gsub(/\s+/, '')
      return unless size.match(/(\d+)x(\d+)/)

      width, height = size.split('x').map(&:to_i)
      gravity = 'centre' # ruby-vips in Rails 8 requires British spelling 'centre'

      url = cdn_image_url(attachment.variant(
        resize_and_pad: [width, height, { gravity: gravity, background: [255, 255, 255] }],
        saver: { quality: quality }
      ))
      enforce_https_if_needed(url)
    rescue ActiveStorage::FileNotFoundError => _e
      nil
    end

    def original_url
      url = cdn_image_url(attachment)
      enforce_https_if_needed(url)
    rescue ActiveStorage::FileNotFoundError => _e
      nil
    end

    private

    def enforce_https_if_needed(url)
      return if url.blank?

      if Rails.env.production? || ENV['FORCE_SSL'] == 'true' || ENV['ASSUME_SSL'] == 'true'
        url.sub(%r{\Ahttp://}, 'https://')
      else
        url
      end
    end

    def translate_gravity_for_mini_magick(_gravity)
      'centre'
    end
  end
end

Spree::ImageMethods.prepend(Spree::ImageMethodsDecorator)
