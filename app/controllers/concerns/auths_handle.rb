module AuthsHandle
  extend ActiveSupport::Concern
  ACCESS_EXPIRY = 1.days
  REFRESH_EXPIRY = 7.days

  class << self
    def authenticate_user(user, unencrypted_password)
      return false if user.password.blank?

      BCrypt::Password.new(user.password) == unencrypted_password
    end

    # Kiểm tra xem email đã được xác thực chưa
    def email_confirmed?(user)
      user.confirm_email == true
    end

    def decode_email_confirmation_token(token)
      secret = Rails.application.secret_key_base

      begin
        decoded_token = JWT.decode(token, secret, true, { algorithm: "HS256" })
        decoded_token[0]["user_id"]
      rescue JWT::ExpiredSignature, JWT::DecodeError
        nil
      end
    end

    # Tạo token xác thực email cho user
    def generate_email_confirmation_token(user)
      payload = {
        user_id: user.id,
        exp: 15.minutes.from_now.to_i,
      }
      secret = Rails.application.secret_key_base

      JWT.encode(payload, secret, "HS256")
    end

    def generate_access_token(payload)
      payload[:exp] = ACCESS_EXPIRY.from_now.to_i
      JWT.encode(payload, ENV["JWT_ACCESS_SECRET_KEY"], "HS256")
    end

    def generate_refresh_token(payload)
      payload[:exp] = REFRESH_EXPIRY.from_now.to_i
      JWT.encode(payload, ENV["JWT_REFRESH_SECRET_KEY"], "HS256")
    end

    def decode_access_token(token)
      decoded = JWT.decode(token, ENV["JWT_ACCESS_SECRET_KEY"], true, algorithm: "HS256")
      decoded[0].with_indifferent_access
    rescue JWT::ExpiredSignature
      raise StandardError, "Access token expired"
    rescue JWT::DecodeError
      raise StandardError, "Invalid access token"
    end

    def decode_refresh_token(token)
      decoded = JWT.decode(token, ENV["JWT_REFRESH_SECRET_KEY"], true, algorithm: "HS256")
      decoded[0].with_indifferent_access
    rescue JWT::ExpiredSignature
      raise StandardError, "Refresh token expired"
    rescue JWT::DecodeError
      raise StandardError, "Invalid refresh token"
    end
  end
end
