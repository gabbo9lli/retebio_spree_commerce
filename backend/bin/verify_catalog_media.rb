# frozen_string_literal: true

puts "\n=============================================="
puts "  RETEBIO: VERIFICA IMMAGINI MEDIA CATALOGO   "
puts "=============================================="

total_assets = Spree::Asset.count
total_blobs = ActiveStorage::Blob.count
puts "Totale Asset Spree: #{total_assets}"
puts "Totale Blob Active Storage: #{total_blobs}"

products_with_images = Spree::Product.joins(variants_including_master: :images).distinct.count
puts "Prodotti con immagini associate: #{products_with_images}"

# Verifica presenza file fisici su disco per il servizio Active Storage
missing_files = 0
valid_files = 0

ActiveStorage::Blob.find_each do |blob|
  service = blob.service
  if service.exist?(blob.key)
    valid_files += 1
  else
    missing_files += 1
  end
end

puts "Verifica storage su disco:"
puts " - Immagini con file presente su disco: #{valid_files}"
puts " - Immagini con file mancante: #{missing_files}"

# Test serializzazione URL immagine per il primo prodotto con immagine
sample_product = Spree::Product.joins(variants_including_master: :images).first
if sample_product && sample_product.images.any?
  sample_img = sample_product.images.first
  url = Rails.application.routes.url_helpers.rails_blob_url(sample_img.attachment, host: 'http://localhost:4000') rescue nil
  puts "Test URL immagine prodotto '#{sample_product.name}': #{url}"
end

puts "=============================================="
