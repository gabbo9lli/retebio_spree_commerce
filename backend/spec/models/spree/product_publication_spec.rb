# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Spree::Product Publication Logic', type: :model do
  let!(:store) { Spree::Store.default || create(:store) }
  let!(:shipping_category) { create(:shipping_category) }

  it 'considera pubblicato un prodotto con data di attivazione (available_on) passata' do
    product = create(:product, available_on: 1.day.ago, price: 10.0, stores: [store])
    expect(Spree::Product.available).to include(product)
    expect(product.available?).to be true
    expect(product.status).to eq('active')
  end

  it 'non pubblica un prodotto con data di attivazione futura' do
    product = create(:product, available_on: 10.days.from_now, price: 10.0, stores: [store])
    expect(Spree::Product.available).not_to include(product)
    expect(product.available?).to be false
    expect(product.status).to eq('draft')
  end

  it 'non pubblica un prodotto con data di attivazione non valorizzata (nil)' do
    product = create(:product, available_on: nil, price: 10.0, stores: [store])
    expect(Spree::Product.available).not_to include(product)
    expect(product.available?).to be false
    expect(product.status).to eq('draft')
  end
end
