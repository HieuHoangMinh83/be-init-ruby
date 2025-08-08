require_dependency Rails.root.join("app", "dto", "user_dto", "user_registration_dto")

class V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [:login, :register]

  def login
    user = User.find_by(email: params[:email])

    # Kiểm tra user tồn tại & password đúng
    if user&.authenticate(params[:password])
      # Kiểm tra user đã active chưa
      unless user.active
        return render json: { error: "User chưa được kích hoạt" }, status: :forbidden
      end

      # Tạo access_token với payload gồm user_id và thời gian hết hạn
      payload = { user_id: user.id, exp: 15.minutes.from_now.to_i }
      access_token = JWT.encode(payload, Rails.application.secrets.secret_key_base)

      # Tạo refresh_token ngẫu nhiên
      refresh_token = SecureRandom.hex(64)
      user.update(refresh_token: refresh_token)

      render json: {
               access_token: access_token,
               refresh_token: refresh_token,
               user: {
                 id: user.id,
                 email: user.email,
                 full_name: user.fullName,
                 role: user.role,
                 active: user.active,
               },
             }, status: :ok
    else
      render json: { error: "Email hoặc mật khẩu không đúng" }, status: :unauthorized
    end
  end

  def activate
    user = User.find(params[:id])

    unless current_user.role == "admin"
      return render json: { error: "Forbidden" }, status: :forbidden
    end

    if user.update(active: true)
      render json: { message: "User activated", user: user }
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def register
    registration = UserDto::UserRegistrationDto.new(user_params.to_h)

    if registration.save
      render json: { message: "User created successfully" }, status: :created
    else
      render json: { errors: registration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :email, :age, :raw_password, :password_confirmation, :role, :active)
  end
end
