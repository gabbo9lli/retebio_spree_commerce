# frozen_string_literal: true

class Spree::AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  include Spree::UserMethods

  def valid_password?(password)
    return false if encrypted_password.blank?

    if encrypted_password.start_with?('$2a$', '$2b$', '$2y$')
      super
    elsif respond_to?(:password_salt) && password_salt.present?
      digest = "#{password}#{password_salt}"
      20.times { digest = Digest::SHA512.hexdigest(digest) }
      if Devise.secure_compare(digest, encrypted_password)
        self.password = password
        self.password_confirmation = password
        self.password_salt = nil
        save(validate: false)
        true
      else
        false
      end
    else
      false
    end
  rescue BCrypt::Errors::InvalidHash
    false
  end
end
