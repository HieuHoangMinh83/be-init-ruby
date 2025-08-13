class ApplicationController < ActionController::API
  before_action :authenticate_request

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header.present?

    decoded = token.present? ? JsonWebToken.decode_access_token(token) : nil
    unless decoded&.dig(:user_id)
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    user = User.find_by(id: decoded[:user_id])
    @current_user = user&.attributes&.except("password", "refresh_token")
    unless @current_user.present?
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def render_success(data:, message: "Thành công", status: :ok, serializer: nil)
    if serializer
      data = ActiveModelSerializers::SerializableResource.new(data, serializer: serializer)
    end

    render json: {
      success: true,
      message: message,
      data: data
    }, status: status
  end

  def render_error(message: 'Lỗi xảy ra', errors: [], status: :bad_request)
    render json: {
      success: false,
      message: message,
      errors: errors
    }, status: status
  end
end
