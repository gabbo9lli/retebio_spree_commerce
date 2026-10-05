# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActiveStorage::Representations::BaseController.class_eval do
    rescue_from ActiveStorage::FileNotFoundError do |_e|
      svg = Spree::ImagesHelperDecorator::FALLBACK_PLACEHOLDER_SVG rescue nil
      if svg
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      else
        head :not_found
      end
    end
  end

  ActiveStorage::Blobs::ProxyController.class_eval do
    rescue_from ActiveStorage::FileNotFoundError do |_e|
      svg = Spree::ImagesHelperDecorator::FALLBACK_PLACEHOLDER_SVG rescue nil
      if svg
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      else
        head :not_found
      end
    end
  end
end
