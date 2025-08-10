class ApplicationController < ActionController::API
  before_action :authenticate_request

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header.present?

    decoded = token.present? ? JsonWebToken.decode_access_token(token) : nil
    return render json: { error: "Unauthorized" }, status: :unauthorized unless decoded&.dig(:user_id)

    user = User.find_by(id: decoded[:user_id])
    @current_user = user.attributes.except("password", "refresh_token")
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user.present?
  end
end
