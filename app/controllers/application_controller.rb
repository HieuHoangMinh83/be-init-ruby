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
    unless user.present?
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    # giữ current_user là object ActiveRecord
    @current_user = user
  end

  # Khi render JSON, loại bỏ field nhạy cảm
  def render_success(data:, message: "Thành công", status: :ok, serializer: nil)
    if serializer
      data = ActiveModelSerializers::SerializableResource.new(data, serializer: serializer)
    else
      # nếu data là ActiveRecord object, loại bỏ password, refresh_token
      if data.respond_to?(:as_json)
        data = data.as_json(except: [:password, :refresh_token])
      end
    end

    render json: {
      success: true,
      message: message,
      data: data,
    }, status: status
  end

  def render_error(message: "Lỗi xảy ra", errors: [], status: :bad_request)
    render json: {
      success: false,
      message: message,
      errors: errors,
    }, status: status
  end
end
