# app/services/json_web_token.rb
class JsonWebToken
  ACCESS_EXPIRY  = 15.minutes
  REFRESH_EXPIRY = 7.days

  def self.generate_access_token(payload)
    payload[:exp] = ACCESS_EXPIRY.from_now.to_i
    JWT.encode(payload, ENV['JWT_ACCESS_SECRET_KEY'], 'HS256')
  end

  def self.generate_refresh_token(payload)
    payload[:exp] = REFRESH_EXPIRY.from_now.to_i
    JWT.encode(payload, ENV['JWT_REFRESH_SECRET_KEY'], 'HS256')
  end

  def self.decode_access_token(token)
    decoded = JWT.decode(token, ENV['JWT_ACCESS_SECRET_KEY'], true, algorithm: 'HS256')
    decoded[0].with_indifferent_access
  rescue JWT::ExpiredSignature
    raise StandardError, 'Access token expired'
  rescue JWT::DecodeError
    raise StandardError, 'Invalid access token'
  end

  def self.decode_refresh_token(token)
    decoded = JWT.decode(token, ENV['JWT_REFRESH_SECRET_KEY'], true, algorithm: 'HS256')
    decoded[0].with_indifferent_access
  rescue JWT::ExpiredSignature
    raise StandardError, 'Refresh token expired'
  rescue JWT::DecodeError
    raise StandardError, 'Invalid refresh token'
  end
end
