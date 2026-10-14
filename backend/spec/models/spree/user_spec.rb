# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::User, type: :model do
  describe '#valid_password?' do
    let(:password) { 'secret123' }

    context 'with standard bcrypt password' do
      let(:user) { described_class.create!(email: 'bcrypt_user@example.com', password: password, password_confirmation: password) }

      it 'returns true for the correct password' do
        expect(user.valid_password?(password)).to be true
      end

      it 'returns false for an incorrect password' do
        expect(user.valid_password?('wrong_password')).to be false
      end
    end

    context 'with legacy authlogic_sha512 password and salt' do
      let(:salt) { 'test_salt_12345' }
      let(:legacy_hash) do
        d = "#{password}#{salt}"
        20.times { d = Digest::SHA512.hexdigest(d) }
        d
      end
      let(:user) do
        u = described_class.new(email: 'legacy_user@example.com')
        u.encrypted_password = legacy_hash
        u.password_salt = salt
        u.save(validate: false)
        u
      end

      it 'authenticates successfully and auto-upgrades to bcrypt' do
        expect(user.encrypted_password).to eq(legacy_hash)
        expect(user.password_salt).to eq(salt)

        expect(user.valid_password?(password)).to be true

        user.reload
        expect(user.encrypted_password).to match(/\A\$2[aby]\$/)
        expect(user.password_salt).to be_nil
        expect(user.valid_password?(password)).to be true
      end

      it 'returns false for incorrect password without modifying user' do
        expect(user.valid_password?('wrong_password')).to be false
        user.reload
        expect(user.encrypted_password).to eq(legacy_hash)
        expect(user.password_salt).to eq(salt)
      end
    end

    context 'with invalid or corrupted hash format' do
      let(:user) do
        u = described_class.new(email: 'corrupt_user@example.com')
        u.encrypted_password = 'not_a_valid_hash_string'
        u.save(validate: false)
        u
      end

      it 'returns false gracefully without raising BCrypt::Errors::InvalidHash' do
        expect { expect(user.valid_password?('any_password')).to be false }.not_to raise_error
      end
    end
  end
end
