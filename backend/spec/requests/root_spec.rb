# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root redirect in headless mode', type: :request do
  it 'reindirizza la root / verso /admin' do
    get '/'
    expect(response).to redirect_to('/admin')
  end
end
