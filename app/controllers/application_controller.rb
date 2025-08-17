class ApplicationController < ActionController::API
  before_action :authenticate_request

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header.present?

    decoded = token.present? ? AuthsHandle.decode_access_token(token) : nil
    unless decoded&.dig(:user_id)
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    user = User.find_by(id: decoded[:user_id])
    unless user.present?
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    # giữ current_user là object ActiveRecord
    @current_user = user
  end

  # Khi render JSON, loại bỏ field nhạy cảm

end
