class User < ApplicationRecord
  include BCrypt

  # Gán password và mã hóa trước khi lưu
  def password=(new_password)
    self[:password] = Password.create(new_password) if new_password.present?
  end

  # So sánh password nhập vào với hash trong DB
  def authenticate(unencrypted_password)
    return false if self[:password].blank?

    BCrypt::Password.new(self[:password]) == unencrypted_password
  end
end
