class UserMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  default from: ENV.fetch("GMAIL_USERNAME", "no-reply@example.com")

  def confirmation_email(user, token)
    @user = user
    @token = token
    base_url = ENV.fetch("BASE_URL", "http://localhost:3000")

    @confirm_url = "#{base_url}/v1/auth/confirm_email?token=#{@token}"

    mail(to: @user.email, subject: "Xác thực tài khoản của bạn")
  end
end
