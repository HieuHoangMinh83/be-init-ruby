# DTOs are autoloaded via config.autoload_paths; no manual requires needed

class V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: %i[login register]

  def login
    dto = UserDto::UserLoginDto.new(login_params)
    return render json: { errors: dto.errors.full_messages }, status: :unprocessable_entity unless dto.valid?

    user = User.find_by(email: dto.email.to_s.downcase)

    unless user&.authenticate(dto.password)
      return render json: { error: "Email hoặc mật khẩu không đúng" }, status: :unauthorized
    end

    return render json: { error: "Tài khoản chưa được kích hoạt" }, status: :forbidden unless user.active

    # Access token hết hạn sau 15 phút (dùng helper JsonWebToken để đồng bộ mã hóa/giải mã)
    access_token = JsonWebToken.generate_access_token(user_id: user.id)
    refresh_token = JsonWebToken.generate_refresh_token(user_id: user.id)
    user.update!(refresh_token: refresh_token)
    render json: {
      access_token: access_token,
      refresh_token: refresh_token,
      user: V1::User::UserLoginSerializer.new(user),
    }, status: :ok
  end

  def activate
    user = User.find(params[:id])

    return render json: { error: "Forbidden" }, status: :forbidden unless current_user.role == "admin"

    if user.update(active: true)
      render json: { message: "User activated", user: user }
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def register
    dto = UserDto::UserRegistrationDto.new(user_params.to_h)

    return render json: { errors: dto.errors.full_messages }, status: :unprocessable_entity unless dto.valid?

    # Kiểm tra email trùng lặp (đơn giản) trước khi tạo
    if User.exists?(email: dto.email.to_s.downcase)
      return render json: { errors: ["Email đã tồn tại"] }, status: :unprocessable_entity
    end

    user = User.new(
      fullName: dto.full_name,
      email: dto.email.to_s.downcase,
      password: dto.password,
      role: "user",
    )

    if user.save
      render json: {
        message: "Tạo user thành công",
        user: {
          id: user.id,
          email: user.email,
          full_name: user.fullName,
          role: user.role,
          active: user.active,
        },
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def refresh
    refresh_token = params[:refresh_token]

    if refresh_token.blank?
      return render json: { error: "Refresh token không được để trống" }, status: :bad_request
    end

    begin
      payload = JsonWebToken.decode_refresh_token(refresh_token)
      user = User.find_by(id: payload[:user_id])

      if user.nil?
        return render json: { error: "User không tồn tại" }, status: :unauthorized
      end

      # Tạo access token mới
      access_token = JsonWebToken.generate_access_token({ user_id: user.id })

      render json: {
        access_token: access_token,
        user: {
          id: user.id,
          email: user.email,
          full_name: user.fullName,
          role: user.role,
          active: user.active,
        },
      }, status: :ok
    rescue StandardError => e
      # Nếu refresh token hết hạn hoặc không hợp lệ thì vào đây
      render json: { error: e.message }, status: :unauthorized
    end
  end

  def logout
    # Xóa refresh_token trong DB để làm mất hiệu lực
    if current_user.update(refresh_token: nil)
      render json: { message: "Đăng xuất thành công" }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def info
    render json: { user: current_user }
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :email, :password)
  end

  def login_params
    params.require(:user).permit(:email, :password)
  end
end
