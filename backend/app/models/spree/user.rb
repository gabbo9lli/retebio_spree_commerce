class Spree::User < Spree.base_class
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Spree modules
  include Spree::UserAddress
  include Spree::UserMethods
  include Spree::UserPaymentSource

  after_save :ensure_addresses_user_id

  def valid_password?(password)
    return false if encrypted_password.blank?

    if encrypted_password.start_with?('$2a$', '$2b$', '$2y$')
      super
    elsif password_salt.present?
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

  private

  def ensure_addresses_user_id
    if bill_address_id.present? && bill_address&.user_id != id
      bill_address.update_column(:user_id, id)
    end
    if ship_address_id.present? && ship_address&.user_id != id
      ship_address.update_column(:user_id, id)
    end
  end
end
