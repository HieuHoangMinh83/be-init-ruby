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

  # Kiểm tra xem email đã được xác thực chưa
  def email_confirmed?
    self.confirm_email == true
  end

  def self.decode_email_confirmation_token(token)
    secret = Rails.application.secret_key_base

    begin
      decoded_token = JWT.decode(token, secret, true, { algorithm: "HS256" })
      decoded_token[0]["user_id"]
    rescue JWT::ExpiredSignature, JWT::DecodeError
      nil
    end
  end

  # Tạo token xác thực email cho user (đã có ở ví dụ trước)
  def generate_email_confirmation_token
    payload = {
      user_id: self.id,
      exp: 15.minutes.from_now.to_i,
    }
    secret = Rails.application.secret_key_base

    JWT.encode(payload, secret, "HS256")
  end
end
