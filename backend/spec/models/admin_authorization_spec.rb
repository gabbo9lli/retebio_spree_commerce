# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Role Authorization', type: :model do
  let!(:admin_role) { Spree::Role.find_by(name: 'admin') || Spree::Role.create!(name: 'admin') }
  let!(:store) { Spree::Store.default || create(:store) }
  let!(:admin_user) do
    admin = Spree::AdminUser.find_by(email: 'admin@retebio.it') || Spree::AdminUser.create!(email: 'admin@retebio.it', password: 'password123', password_confirmation: 'password123')
    admin.add_role('admin', store)
    admin
  end

  it 'garantisce i permessi di amministrazione completa ad admin@retebio.it' do
    expect(admin_user.spree_admin?(store)).to be true
    expect(admin_user.has_spree_role?('admin', store)).to be true

    ability = Spree::Ability.new(admin_user, { store: store })
    expect(ability.can?(:admin, :overview)).to be true
    expect(ability.can?(:manage, :all)).to be true
  end
end
