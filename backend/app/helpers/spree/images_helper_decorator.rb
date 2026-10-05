# frozen_string_literal: true

module Spree
  module ImagesHelperDecorator
    FALLBACK_PLACEHOLDER_SVG = 'data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22200%22%20height%3D%22200%22%20viewBox%3D%220%200%20200%20200%22%3E%3Crect%20fill%3D%22%23f3f4f6%22%20width%3D%22200%22%20height%3D%22200%22%2F%3E%3Ctext%20fill%3D%22%239ca3af%22%20font-family%3D%22sans-serif%22%20font-size%3D%2214%22%20x%3D%2250%25%22%20y%3D%2250%25%22%20text-anchor%3D%22middle%22%20dominant-baseline%3D%22middle%22%3EImmagine%20non%20disponibile%3C%2Ftext%3E%3C%2Fsvg%3E'

    def spree_image_url(image, options = {})
      return unless image
      return unless image.variable?
      return if image.respond_to?(:attached?) && !image.attached?

      # Se il file binario non è presente fisicamente su disco nello storage locale
      if image.blob&.service&.respond_to?(:exist?) && !image.blob.service.exist?(image.blob.key)
        return FALLBACK_PLACEHOLDER_SVG
      end

      super
    end
  end
end

Spree::ImagesHelper.prepend(Spree::ImagesHelperDecorator)
