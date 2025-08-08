class User < ApplicationRecord
  include BCrypt

  attr_accessor :raw_password  # Thêm dòng này để User có thể nhận raw_password

  # Gán password: tự mã hóa rồi lưu vào trường password
  def password=(new_password)
    self[:password] = Password.create(new_password)
  end

  # Xác thực password
  def authenticate(unencrypted_password)
    return false if self[:password].blank?
    Password.new(self[:password]) == unencrypted_password
  end

  before_save :encrypt_password, if: -> { raw_password.present? }

  private

  def encrypt_password
    self.password = raw_password
  end
end
