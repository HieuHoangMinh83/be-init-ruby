# Hướng dẫn Setup Mailer cho Rails App

## 🎯 Mục tiêu

Hướng dẫn chi tiết cách setup email để gửi email xác thực tài khoản trong Rails app, từ cài đặt thư viện đến gửi tin nhắn thành công.

## 📋 Yêu cầu

- Rails app đã có sẵn
- Tài khoản Gmail
- Server production (VPS, Heroku, etc.)

---

## 🚀 Bước 1: Hiểu cách hoạt động

### Email xác thực hoạt động như thế nào?

1. User đăng ký → Tạo tài khoản mới
2. Hệ thống gửi email chứa link xác thực
3. User click link → Kích hoạt tài khoản
4. User có thể đăng nhập

### Code hiện tại đã có gì?

- ✅ `UserMailer` class
- ✅ `confirmation_email` method
- ✅ Email template HTML
- ✅ Gọi mailer trong `AuthController`

---

## 📦 Bước 2: Cài đặt thư viện cần thiết

### 2.1 Kiểm tra Gemfile

Mở file `Gemfile` và đảm bảo có các gem sau:

```ruby
# Gemfile
source "https://rubygems.org"

# Rails core
gem "rails", "~> 7.0.0"

# Mailer (đã có sẵn trong Rails)
# Action Mailer được include tự động

# Background job (khuyến nghị)
gem "sidekiq"  # Thêm vào nếu muốn gửi email background

# JWT cho token (nếu chưa có)
gem "jwt"  # Thêm vào nếu chưa có
```

### 2.2 Cài đặt gems

```bash
# Trong terminal, chạy:
bundle install
```

### 2.3 Kiểm tra cài đặt

```bash
# Kiểm tra Rails có Action Mailer không
rails runner "puts ActionMailer::Base.delivery_method"
# Kết quả mong đợi: smtp
```

---

## 🔧 Bước 3: Tạo và cấu hình Mailer

### 3.1 Tạo Mailer (nếu chưa có)

```bash
# Tạo mailer mới (nếu chưa có UserMailer)
rails generate mailer UserMailer
```

### 3.2 Cấu hình UserMailer

Mở file `app/mailers/user_mailer.rb` và đảm bảo có code sau:

```ruby
class UserMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  default from: ENV.fetch("GMAIL_USERNAME", "no-reply@example.com")

  def confirmation_email(user)
    @user = user
    @token = user.generate_email_confirmation_token
    base_url = ENV.fetch("BASE_URL", "http://localhost:3000")

    @confirm_url = "#{base_url}/v1/auth/confirm_email?token=#{@token}"

    mail(to: @user.email, subject: "Xác thực tài khoản của bạn")
  end
end
```

### 3.3 Tạo email template

Tạo file `app/views/user_mailer/confirmation_email.html.erb`:

```erb
<!DOCTYPE html>
<html>
<head>
  <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
</head>
<body>
  <h1>Xin chào <%= @user.fullName %>!</h1>

  <p>Chào mừng bạn đến với ứng dụng của chúng tôi.</p>

  <p>Vui lòng click vào link bên dưới để xác thực tài khoản của bạn:</p>

  <p>
    <a href="<%= @confirm_url %>" style="background-color: #4CAF50; color: white; padding: 14px 20px; text-decoration: none; border-radius: 4px;">
      Xác thực tài khoản
    </a>
  </p>

  <p>Hoặc copy link này vào trình duyệt:</p>
  <p><%= @confirm_url %></p>

  <p>Link này sẽ hết hạn sau 24 giờ.</p>

  <p>Nếu bạn không đăng ký tài khoản này, vui lòng bỏ qua email này.</p>

  <p>Trân trọng,<br>Đội ngũ phát triển</p>
</body>
</html>
```

### 3.4 Tạo text version (tùy chọn)

Tạo file `app/views/user_mailer/confirmation_email.text.erb`:

```erb
Xin chào <%= @user.fullName %>!

Chào mừng bạn đến với ứng dụng của chúng tôi.

Vui lòng click vào link bên dưới để xác thực tài khoản của bạn:

<%= @confirm_url %>

Link này sẽ hết hạn sau 24 giờ.

Nếu bạn không đăng ký tài khoản này, vui lòng bỏ qua email này.

Trân trọng,
Đội ngũ phát triển
```

---

## ⚙️ Bước 4: Cấu hình Model User

### 4.1 Thêm method vào User model

Mở file `app/models/user.rb` và thêm method sau:

```ruby
class User < ApplicationRecord
  # ... existing code ...

  # Method tạo token xác thực email
  def generate_email_confirmation_token
    # Tạo token với thời gian hết hạn 24 giờ
    payload = {
      user_id: id,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end

  # Method decode token
  def self.decode_email_confirmation_token(token)
    begin
      decoded = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })
      decoded[0]['user_id']
    rescue JWT::ExpiredSignature
      nil # Token hết hạn
    rescue JWT::DecodeError
      nil # Token không hợp lệ
    end
  end

  # Method kiểm tra email đã xác thực chưa
  def email_confirmed?
    confirm_email == true
  end
end
```

### 4.2 Kiểm tra database migration

Đảm bảo có các cột cần thiết trong bảng users:

```ruby
# Trong db/migrate/xxx_add_email_confirmation_to_users.rb
class AddEmailConfirmationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :confirm_email, :boolean, default: false
    add_column :users, :confirm_email_at, :datetime
  end
end
```

Chạy migration nếu chưa có:

```bash
rails db:migrate
```

---

## 🔧 Bước 5: Cấu hình Controller

### 5.1 Cập nhật AuthController

Mở file `app/controllers/v1/auth_controller.rb` và đảm bảo có code sau:

```ruby
class V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: %i[login register confirm_email]

  # ... existing login method ...

  def register
    dto = UserRegistrationDto.new(user_params.to_h)

    return render_error(errors: dto.errors.full_messages, status: :unprocessable_entity) unless dto.valid?

    # Kiểm tra email trùng lặp
    if User.exists?(email: dto.email.to_s.downcase)
      return render_error(errors: ["Email đã tồn tại"], status: :unprocessable_entity)
    end

    user = User.new(
      fullName: dto.full_name,
      email: dto.email.to_s.downcase,
      password: dto.password,
      role: "user",
      active: false, # Chưa kích hoạt cho đến khi xác thực email
      confirm_email: false
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

    render "auth/confirm_email", layout: false
  end

  # ... existing methods ...
end
```

### 5.2 Tạo view cho confirm_email

Tạo file `app/views/v1/auth/confirm_email.html.erb`:

```erb
<!DOCTYPE html>
<html>
<head>
  <title>Xác thực Email</title>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
    .success { color: green; }
    .error { color: red; }
    .container { max-width: 600px; margin: 0 auto; }
  </style>
</head>
<body>
  <div class="container">
    <% if @success %>
      <h1 class="success">✅ Xác thực thành công!</h1>
      <p>Tài khoản của bạn đã được kích hoạt thành công.</p>
      <p>Bây giờ bạn có thể đăng nhập vào ứng dụng.</p>
    <% else %>
      <h1 class="error">❌ Xác thực thất bại</h1>
      <p class="error"><%= @error_message %></p>
      <p>Vui lòng thử lại hoặc liên hệ hỗ trợ.</p>
    <% end %>
  </div>
</body>
</html>
```

---

## 🔧 Bước 6: Cấu hình Environment

### 6.1 Cấu hình Development

Mở file `config/environments/development.rb` và đảm bảo có:

```ruby
# Configure Action Mailer for development
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.smtp_settings = {
  address: "smtp.gmail.com",
  port: 587,
  domain: "gmail.com",
  user_name: ENV["GMAIL_USERNAME"],
  password: ENV["GMAIL_PASSWORD"],
  authentication: "plain",
  enable_starttls_auto: true,
}
```

### 6.2 Cấu hình Production

Mở file `config/environments/production.rb` và đảm bảo có:

```ruby
# Configure Action Mailer for production
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = false
config.action_mailer.smtp_settings = {
  address: "smtp.gmail.com",
  port: 587,
  domain: "gmail.com",
  user_name: ENV["GMAIL_USERNAME"],
  password: ENV["GMAIL_PASSWORD"],
  authentication: "plain",
  enable_starttls_auto: true,
}

# Set default URL options for Action Mailer
config.action_mailer.default_url_options = {
  host: ENV["BASE_URL"] || "yourdomain.com",
  protocol: "https"
}
```

---

## 🔧 Bước 7: Setup Gmail App Password

### 7.1 Tạo App Password cho Gmail

**Lưu ý quan trọng:** Không dùng password Gmail thường, phải tạo App Password!

1. **Vào Google Account Settings**

   - Truy cập: https://myaccount.google.com/
   - Click "Security" (Bảo mật)

2. **Bật 2-Factor Authentication**

   - Tìm "2-Step Verification"
   - Bật nếu chưa bật

3. **Tạo App Password**
   - Tìm "App passwords" (Mật khẩu ứng dụng)
   - Chọn "Mail" và "Other (Custom name)"
   - Đặt tên: "Rails App"
   - Copy password được tạo ra

### 7.2 Set Environment Variables

**Cách 1: Export trực tiếp (tạm thời)**

```bash
# Set environment variables
export GMAIL_USERNAME="your-email@gmail.com"
export GMAIL_PASSWORD="your-app-password-here"
export BASE_URL="https://yourdomain.com"
```

**Cách 2: Thêm vào ~/.bashrc (lâu dài)**

```bash
# Mở file
nano ~/.bashrc

# Thêm vào cuối file
export GMAIL_USERNAME="your-email@gmail.com"
export GMAIL_PASSWORD="your-app-password-here"
export BASE_URL="https://yourdomain.com"

# Lưu và reload
source ~/.bashrc
```

**Cách 3: Nếu dùng Heroku**

```bash
heroku config:set GMAIL_USERNAME="your-email@gmail.com"
heroku config:set GMAIL_PASSWORD="your-app-password-here"
heroku config:set BASE_URL="https://your-app.herokuapp.com"
```

---

## 🧪 Bước 8: Test cấu hình

### 8.1 Test trong Rails Console

```bash
# SSH vào server
ssh user@your-server.com

# Vào thư mục app
cd /path/to/your/rails/app

# Mở Rails console
rails console

# Test gửi email
user = User.first
UserMailer.confirmation_email(user).deliver_now
```

### 8.2 Kiểm tra logs

```bash
# Xem logs real-time
tail -f log/production.log

# Tìm log email
grep "Mailer" log/production.log
```

### 8.3 Test đăng ký user mới

1. Vào app và đăng ký user mới
2. Kiểm tra email có nhận được không
3. Click link xác thực trong email

---

## 🔍 Bước 9: Troubleshooting

### Email không gửi được?

**Kiểm tra 1: Environment Variables**

```bash
# Kiểm tra biến môi trường
echo $GMAIL_USERNAME
echo $GMAIL_PASSWORD
echo $BASE_URL
```

**Kiểm tra 2: Gmail App Password**

- Đảm bảo đã tạo App Password, không phải password thường
- Kiểm tra 2-Factor Authentication đã bật

**Kiểm tra 3: Logs**

```bash
# Xem lỗi chi tiết
tail -f log/production.log | grep -i error
```

**Kiểm tra 4: Firewall**

- Port 587 phải mở
- Nếu dùng VPS, kiểm tra firewall settings

### Email bị spam?

- Setup SPF, DKIM records cho domain
- Dùng email business thay vì Gmail cá nhân
- Tránh từ khóa spam trong subject/content

---

## 📁 File cấu hình quan trọng

### 1. `config/environments/production.rb`

```ruby
# Cấu hình SMTP đã có sẵn
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: "smtp.gmail.com",
  port: 587,
  domain: "gmail.com",
  user_name: ENV["GMAIL_USERNAME"],
  password: ENV["GMAIL_PASSWORD"],
  authentication: "plain",
  enable_starttls_auto: true,
}
```

### 2. `app/mailers/user_mailer.rb`

```ruby
class UserMailer < ApplicationMailer
  default from: ENV.fetch("GMAIL_USERNAME", "no-reply@example.com")

  def confirmation_email(user)
    @user = user
    @token = user.generate_email_confirmation_token
    @confirm_url = "#{ENV.fetch('BASE_URL', 'http://localhost:3000')}/v1/auth/confirm_email"
    mail(to: @user.email, subject: "Xác thực tài khoản của bạn")
  end
end
```

### 3. `app/controllers/v1/auth_controller.rb`

```ruby
# Trong method register
if user.save
  UserMailer.confirmation_email(user).deliver_later  # Gửi email
  # ...
end
```

---

## 🎯 Checklist hoàn thành

- [ ] Cài đặt gems cần thiết
- [ ] Tạo và cấu hình UserMailer
- [ ] Tạo email templates
- [ ] Cập nhật User model với methods xác thực
- [ ] Cấu hình AuthController
- [ ] Tạo view confirm_email
- [ ] Cấu hình environment files
- [ ] Tạo Gmail App Password
- [ ] Set environment variables trên server
- [ ] Test gửi email trong console
- [ ] Test đăng ký user mới
- [ ] Kiểm tra email nhận được
- [ ] Test click link xác thực

---

## 💡 Tips

1. **Luôn dùng App Password**, không dùng password Gmail thường
2. **Test kỹ trước khi deploy** production
3. **Monitor logs** để phát hiện lỗi sớm
4. **Backup environment variables** để không bị mất
5. **Dùng background job** (Sidekiq) để tránh block request

---

## 🆘 Cần giúp đỡ?

Nếu gặp vấn đề:

1. Kiểm tra logs: `tail -f log/production.log`
2. Verify environment variables
3. Test từng bước một
4. Liên hệ support nếu cần

**Lưu ý:** Đảm bảo thay thế các giá trị `your-email@gmail.com`, `your-app-password-here`, `yourdomain.com` bằng giá trị thực tế của bạn!
