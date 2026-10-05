# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::LineItem, type: :model do
  let(:order) { create(:order) }
  let(:product) { create(:product, weight: 2) }
  let(:variant) { product.master }

  it 'è valido se la quantità è un multiplo esatto del peso/collo (step)' do
    line_item = Spree::LineItem.new(order: order, variant: variant, quantity: 4)
    expect(line_item).to be_valid
  end

  it 'non è valido se la quantità non rispetta lo step del peso' do
    line_item = Spree::LineItem.new(order: order, variant: variant, quantity: 3)
    expect(line_item).not_to be_valid
    expect(line_item.errors[:quantity]).to include("deve essere un multiplo del peso di vendita (2)")
  end
end
