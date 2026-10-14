# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::AdminUser, type: :model do
  describe '#valid_password?' do
    let(:password) { 'admin_secret123' }

    context 'with standard bcrypt password' do
      let(:admin) { described_class.create!(email: 'bcrypt_admin@example.com', password: password, password_confirmation: password) }

      it 'returns true for the correct password' do
        expect(admin.valid_password?(password)).to be true
      end

      it 'returns false for an incorrect password' do
        expect(admin.valid_password?('wrong_password')).to be false
      end
    end

    context 'with legacy authlogic_sha512 password and salt' do
      let(:salt) { 'admin_salt_98765' }
      let(:legacy_hash) do
        d = "#{password}#{salt}"
        20.times { d = Digest::SHA512.hexdigest(d) }
        d
      end
      let(:admin) do
        a = described_class.new(email: 'legacy_admin@example.com')
        a.encrypted_password = legacy_hash
        a.password_salt = salt if a.respond_to?(:password_salt=)
        a.save(validate: false)
        a
      end

      it 'authenticates successfully and auto-upgrades to bcrypt' do
        expect(admin.encrypted_password).to eq(legacy_hash)
        expect(admin.valid_password?(password)).to be true

        admin.reload
        expect(admin.encrypted_password).to match(/\A\$2[aby]\$/)
        expect(admin.valid_password?(password)).to be true
      end

      it 'returns false for incorrect password without modifying user' do
        expect(admin.valid_password?('wrong_password')).to be false
        admin.reload
        expect(admin.encrypted_password).to eq(legacy_hash)
      end
    end

    context 'with invalid or corrupted hash format' do
      let(:admin) do
        a = described_class.new(email: 'corrupt_admin@example.com')
        a.encrypted_password = 'invalid_hash_value'
        a.save(validate: false)
        a
      end

      it 'returns false gracefully without raising BCrypt::Errors::InvalidHash' do
        expect { expect(admin.valid_password?('any_password')).to be false }.not_to raise_error
      end
    end
  end
end
