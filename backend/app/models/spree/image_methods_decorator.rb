# frozen_string_literal: true

module Spree
  module ImageMethodsDecorator
    def generate_url(size:, gravity: 'centre', quality: 80, background: [0, 0, 0])
      return if size.blank?

      size = size.gsub(/\s+/, '')
      return unless size.match(/(\d+)x(\d+)/)

      width, height = size.split('x').map(&:to_i)
      gravity = 'centre' # ruby-vips in Rails 8 requires British spelling 'centre'

      cdn_image_url(attachment.variant(resize_and_pad: [width, height, { gravity: gravity }], saver: { quality: quality }))
    rescue ActiveStorage::FileNotFoundError => _e
      nil
    end

    def original_url
      cdn_image_url(attachment)
    rescue ActiveStorage::FileNotFoundError => _e
      nil
    end

    private

    def translate_gravity_for_mini_magick(_gravity)
      'centre'
    end
  end
end

Spree::ImageMethods.prepend(Spree::ImageMethodsDecorator)
