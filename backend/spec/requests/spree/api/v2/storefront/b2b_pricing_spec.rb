# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'B2B Gated Store API', type: :request do
  let!(:country) { Spree::Country.find_by(iso: 'IT') || create(:country, iso: 'IT') }
  let!(:store) { Spree::Store.default || create(:store, default: true, default_currency: 'EUR', default_country: country) }
  let!(:product) { create(:product, price: 15.50, stores: [store]) }
  let(:user) { create(:user) }

  describe 'GET /api/v2/storefront/products' do
    context 'quando l utente non e autenticato' do
      before { get '/api/v2/storefront/products' }

      it 'restituisce i prodotti senza esporre i prezzi' do
        expect(response).to have_http_status(:ok)
        first_product_attrs = json_response['data'].first['attributes']
        expect(first_product_attrs['price']).to be_nil
        expect(first_product_attrs['display_price']).to be_nil
      end
    end

    context 'quando l utente e autenticato via token' do
      let(:token) { Spree::OauthAccessToken.create!(resource_owner: user, scopes: 'storefront') }

      before do
        get '/api/v2/storefront/products', headers: { 'Authorization' => "Bearer #{token.token}" }
      end

      it 'mostra il prezzo corretto' do
        expect(response).to have_http_status(:ok)
        first_product_attrs = json_response['data'].first['attributes']
        expect(first_product_attrs['price']).to eq('15.5')
        expect(first_product_attrs['display_price']).to be_present
      end
    end
  end

  describe 'POST /api/v2/storefront/cart/add_item' do
    context 'quando l utente anonimo tenta di aggiungere al carrello' do
      it 'risponde con 401 Unauthorized' do
        post '/api/v2/storefront/cart/add_item', params: { variant_id: product.master.id, quantity: 1 }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
