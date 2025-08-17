# DTOs are autoloaded via config.autoload_paths; no manual requires needed

class V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: %i[login register confirm_email]

  def login
    dto = UserLoginDto.new(login_params)

    # Validate user credentials
    validation_result = UsersHandle.validate_user_login(dto)
    if !validation_result[:success]
      return ResponseHandle.render_error(self, message: validation_result[:message], status: validation_result[:status])
    end

    current_user = validation_result[:data][:user]

    # Generate tokens
    tokens = UsersHandle.generate_user_tokens(current_user)

    ResponseHandle.render_success(
      self,
      data: {
        access_token: tokens[:access_token],
        refresh_token: tokens[:refresh_token],
        user: UserLoginSerializer.new(current_user),
      },
      message: "Đăng nhập thành công",
    )
  end

  def activate
    user = User.find(params[:id])
    result = UsersHandle.activate_user(user, current_user)

    if result[:success]
      ResponseHandle.render_success(
        self,
        data: result[:data],
        message: result[:message],
      )
    else
      ResponseHandle.render_error(self, message: result[:message], status: result[:status])
    end
  end

  def register
    dto = UserRegistrationDto.new(user_params.to_h)

    # Validate registration data
    validation_result = UsersHandle.validate_registration_data(dto)
    unless validation_result[:success]
      return ResponseHandle.render_error(self, message: validation_result[:message], status: validation_result[:status])
    end

    # Create new user
    creation_result = UsersHandle.create_user_send_email(dto)
    unless creation_result[:success]
      return ResponseHandle.render_error(self, message: creation_result[:message], status: creation_result[:status])
    end

    current_user = creation_result[:data][:user]

    # Send confirmation email

    ResponseHandle.render_success(
      self,
      data: {
        user: {
          id: current_user.id,
          email: current_user.email,
          full_name: current_user.fullName,
          role: current_user.role,
        },
      },
      message: "Tạo user thành công, vui lòng kiểm tra email để xác thực tài khoản",
      status: :created,
    )
  end

  def confirm_email
    token = params[:token]
    result = UsersHandle.process_email_confirmation(token)

    @success = result[:success]
    @error_message = result[:message]

    if result[:success] && result[:already_confirmed]
      @error_message = "Email đã được xác thực trước đó"
    end

    Rails.logger.info "Rendering view with @success=#{@success}, @error_message=#{@error_message}"
    render "confirm_email", layout: true
  end

  def refresh
    refresh_token = params[:refresh_token]
    result = UsersHandle.refresh_user_tokens(refresh_token)

    if result[:success]
      ResponseHandle.render_success(
        self,
        data: {
          access_token: result[:data][:access_token],
          user: {
            id: result[:data][:user].id,
            email: result[:data][:user].email,
            full_name: result[:data][:user].fullName,
            role: result[:data][:user].role,
            active: result[:data][:user].active,
          },
        },
        message: "Refresh token thành công",
      )
    else
      ResponseHandle.render_error(self, message: result[:message], status: result[:status])
    end
  end

  def logout
    result = UsersHandle.logout_user(current_user)

    if result[:success]
      ResponseHandle.render_success(self, message: "Đăng xuất thành công")
    else
      ResponseHandle.render_error(self, message: result[:message], status: result[:status])
    end
  end

  def info
    ResponseHandle.render_success(
      self,
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
