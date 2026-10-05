# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::V2::Storefront::VariantSerializer do
  let(:product) { create(:product, weight: 5.0) }
  let(:variant) { product.master }

  it 'serializza weight e quantity_step coerentemente con il peso' do
    json = described_class.new(variant).serializable_hash.with_indifferent_access
    attributes = json[:data][:attributes]
    expect(attributes[:weight]).to eq(5.0)
    expect(attributes[:quantity_step]).to eq(5.0)
  end
end
