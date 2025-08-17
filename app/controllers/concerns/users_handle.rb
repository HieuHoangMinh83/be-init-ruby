module UsersHandle
  extend ActiveSupport::Concern

  class << self
    # User creation and validation methods

    # Combined user validation method
    def validate_user_login(dto)
      if !dto.valid?
        return { success: false, message: "Dữ liệu đăng nhập không hợp lệ: #{dto.errors.full_messages.join(", ")}", status: :unprocessable_entity }
      end
      email = dto.email.to_s.downcase
      password = dto.password
      user = User.find_by(email: email.to_s.downcase)

      # Check if user exists and password is correct
      unless user && AuthsHandle.authenticate_user(user, password)
        return { success: false, message: "Email hoặc mật khẩu không đúng", status: :unauthorized }
      end

      # Check email confirmation for all users
      unless AuthsHandle.email_confirmed?(user)
        return { success: false, message: "Vui lòng xác thực email trước khi đăng nhập", status: :forbidden }
      end

      # Check active status for admin users only
      if user.role == "admin" && !user.active
        return { success: false, message: "Tài khoản admin chưa được kích hoạt", status: :forbidden }
      end

      return { success: true, data: { user: user }, message: "Validation successful" }
    end

    # User authentication methods
    def authenticate_user_login(email, password)
      user = User.find_by(email: email.to_s.downcase)

      unless user && AuthsHandle.authenticate_user(user, password)
        return { success: false, message: "Email hoặc mật khẩu không đúng", status: :unauthorized }
      end

      { success: true, data: { user: user }, message: "Authentication successful" }
    end

    def validate_user_login_status(user)
      # Kiểm tra xác thực email cho tất cả users
      unless AuthsHandle.email_confirmed?(user)
        return { success: false, message: "Vui lòng xác thực email trước khi đăng nhập", status: :forbidden }
      end

      # Kiểm tra active chỉ cho admin
      if user.role == "admin" && !user.active
        return { success: false, message: "Tài khoản admin chưa được kích hoạt", status: :forbidden }
      end

      { success: true, message: "User status validated" }
    end

    def generate_user_tokens(user)
      access_token = AuthsHandle.generate_access_token(user_id: user.id)
      refresh_token = AuthsHandle.generate_refresh_token(user_id: user.id)
      user.update!(refresh_token: refresh_token)

      {
        access_token: access_token,
        refresh_token: refresh_token,
        user: UserLoginSerializer.new(user),
      }
    end

    # User registration methods
    def validate_registration_data(dto)
      unless dto.valid?
        return {
                 success: false,
                 message: "Dữ liệu đăng ký không hợp lệ: #{dto.errors.full_messages.join(", ")}",
                 status: :unprocessable_entity,
               }
      end

      # Kiểm tra email trùng lặp
      if User.exists?(email: dto.email.to_s.downcase)
        return {
                 success: false,
                 message: "Email đã tồn tại",
                 status: :unprocessable_entity,
               }
      end

      { success: true, message: "Registration data validated" }
    end

    def create_user_send_email(dto)
      user = User.new(
        fullName: dto.full_name,
        email: dto.email.to_s.downcase,
        password: dto.password,
        role: "user",
        user_setting_attributes: { language: "vi" },
      )

      if user.save
        send_confirmation_email(user)
        return { success: true, data: { user: user }, message: "User created successfully" }
      else
        {
          success: false,
          message: "Không thể tạo user: #{user.errors.full_messages.join(", ")}",
          status: :unprocessable_entity,
        }
      end
    end

    def send_confirmation_email(user)
      token = AuthsHandle.generate_email_confirmation_token(user)
      UserMailer.confirmation_email(user, token).deliver_later
    end

    # User activation methods
    def activate_user(user, current_user)
      unless current_user.role == "admin"
        return { success: false, message: "Forbidden", status: :forbidden }
      end

      if user.update(active: true)
        { success: true, data: { user: user }, message: "User activated successfully" }
      else
        {
          success: false,
          message: "Không thể kích hoạt user: #{user.errors.full_messages.join(", ")}",
          status: :unprocessable_entity,
        }
      end
    end

    # Email confirmation methods
    def process_email_confirmation(token)
      if token.blank?
        return { success: false, message: "Token không được cung cấp" }
      end

      user_id = AuthsHandle.decode_email_confirmation_token(token)
      if user_id.nil?
        return { success: false, message: "Token không hợp lệ hoặc đã hết hạn" }
      end

      user = User.find_by(id: user_id)
      if user.nil?
        return { success: false, message: "User không tồn tại" }
      end

      if AuthsHandle.email_confirmed?(user)
        return { success: true, data: { user: user }, message: "Email đã được xác thực trước đó", already_confirmed: true }
      end

      if user.update(confirm_email: true, confirm_email_at: Time.current, active: true)
        { success: true, data: { user: user }, message: "Email xác thực thành công" }
      else
        { success: false, message: "Có lỗi xảy ra khi cập nhật trạng thái" }
      end
    end

    # Token refresh methods
    def refresh_user_tokens(refresh_token)
      if refresh_token.blank?
        return { success: false, message: "Refresh token không được để trống", status: :bad_request }
      end

      begin
        payload = AuthsHandle.decode_refresh_token(refresh_token)
        user = User.find_by(id: payload[:user_id])

        if user.nil?
          return { success: false, message: "User không tồn tại", status: :unauthorized }
        end

        access_token = AuthsHandle.generate_access_token({ user_id: user.id })
        { success: true, data: { access_token: access_token, user: user }, message: "Token refreshed successfully" }
      rescue StandardError => e
        { success: false, message: e.message, status: :unauthorized }
      end
    end

    # Logout methods
    def logout_user(user)
      if user.update(refresh_token: nil)
        { success: true, message: "Logout successful" }
      else
        {
          success: false,
          message: "Không thể đăng xuất: #{user.errors.full_messages.join(", ")}",
          status: :unprocessable_entity,
        }
      end
    end
  end
end
