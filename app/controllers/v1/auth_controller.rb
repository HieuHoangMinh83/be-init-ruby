# DTOs are autoloaded via config.autoload_paths; no manual requires needed

class V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: %i[login register confirm_email]

  def login
    dto = UserDto::UserLoginDto.new(login_params)
    return render_error(errors: dto.errors.full_messages, status: :unprocessable_entity) unless dto.valid?

    user = User.find_by(email: dto.email.to_s.downcase)

    unless user&.authenticate(dto.password)
      return render_error(message: "Email hoặc mật khẩu không đúng", status: :unauthorized)
    end

    return render_error(message: "Tài khoản chưa được kích hoạt", status: :forbidden) unless user.active

    # Access token hết hạn sau 15 phút (dùng helper JsonWebToken để đồng bộ mã hóa/giải mã)
    access_token = JsonWebToken.generate_access_token(user_id: user.id)
    refresh_token = JsonWebToken.generate_refresh_token(user_id: user.id)
    user.update!(refresh_token: refresh_token)

    render_success(
      data: {
        access_token: access_token,
        refresh_token: refresh_token,
        user: V1::User::UserLoginSerializer.new(user),
      },
      message: "Đăng nhập thành công",
    )
  end

  def activate
    user = User.find(params[:id])

    return render_error(message: "Forbidden", status: :forbidden) unless current_user.role == "admin"

    if user.update(active: true)
      render_success(
        data: { user: user },
        message: "User activated",
      )
    else
      render_error(errors: user.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def register
    dto = UserRegistrationDto.new(user_params.to_h)

    return render_error(errors: dto.errors.full_messages, status: :unprocessable_entity) unless dto.valid?

    # Kiểm tra email trùng lặp (đơn giản) trước khi tạo
    if User.exists?(email: dto.email.to_s.downcase)
      return render_error(errors: ["Email đã tồn tại"], status: :unprocessable_entity)
    end

    user = User.new(
      fullName: dto.full_name,
      email: dto.email.to_s.downcase,
      password: dto.password,
      role: "user",
    )

    if user.save
      # Gửi email xác thực
      UserMailer.confirmation_email(user).deliver_later

      render_success(
        data: {
          user: {
            id: user.id,
            email: user.email,
            full_name: user.fullName,
            role: user.role,
            active: user.active,
          },
        },
        message: "Tạo user thành công, vui lòng kiểm tra email để xác thực tài khoản",
        status: :created,
      )
    else
      render_error(errors: user.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def confirm_email
    token = params[:token]

    if token.blank?
      @success = false
      @error_message = "Token không được cung cấp"
      return render "auth/confirm_email", layout: false
    end

    user_id = User.decode_email_confirmation_token(token)

    if user_id.nil?
      @success = false
      @error_message = "Token không hợp lệ hoặc đã hết hạn"
      return render "auth/confirm_email", layout: false
    end

    user = User.find_by(id: user_id)
    if user.nil?
      @success = false
      @error_message = "User không tồn tại"
      return render "auth/confirm_email", layout: false
    end

    if user.email_confirmed?
      @success = true
      @error_message = nil
      return render "auth/confirm_email", layout: false
    end

    if user.update(confirm_email: true, confirm_email_at: Time.current, active: true)
      @success = true
      @error_message = nil
    else
      @success = false
      @error_message = "Có lỗi xảy ra khi cập nhật trạng thái"
    end

    Rails.logger.info "Rendering view with @success=#{@success}, @error_message=#{@error_message}"
    render "confirm_email", layout: true
  end

  def refresh
    refresh_token = params[:refresh_token]

    if refresh_token.blank?
      return render_error(message: "Refresh token không được để trống", status: :bad_request)
    end

    begin
      payload = JsonWebToken.decode_refresh_token(refresh_token)
      user = User.find_by(id: payload[:user_id])

      if user.nil?
        return render_error(message: "User không tồn tại", status: :unauthorized)
      end

      # Tạo access token mới
      access_token = JsonWebToken.generate_access_token({ user_id: user.id })

      render_success(
        data: {
          access_token: access_token,
          user: {
            id: user.id,
            email: user.email,
            full_name: user.fullName,
            role: user.role,
            active: user.active,
          },
        },
        message: "Refresh token thành công",
      )
    rescue StandardError => e
      # Nếu refresh token hết hạn hoặc không hợp lệ thì vào đây
      render_error(message: e.message, status: :unauthorized)
    end
  end

  def logout
    # Xóa refresh_token trong DB để làm mất hiệu lực
    if current_user.update(refresh_token: nil)
      render_success(message: "Đăng xuất thành công")
    else
      render_error(errors: current_user.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def info
    render_success(
      data: { user: current_user },
      message: "Lấy thông tin user thành công",
    )
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :email, :password)
  end

  def login_params
    params.require(:user).permit(:email, :password)
  end
end
