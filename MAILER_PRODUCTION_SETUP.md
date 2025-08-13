# Cấu hình Mailer cho Production

## 1. Gmail SMTP (Đơn giản nhất)

### Bước 1: Tạo App Password

1. Vào Google Account Settings
2. Bật 2-Factor Authentication
3. Tạo App Password cho ứng dụng Rails

### Bước 2: Set Environment Variables

```bash
# Trên server production
export GMAIL_USERNAME="your-email@gmail.com"
export GMAIL_PASSWORD="your-app-password"
export BASE_URL="https://yourdomain.com"
```

### Bước 3: Kiểm tra cấu hình

Cấu hình Gmail đã được enable trong `config/environments/production.rb`

## 2. SendGrid (Khuyến nghị cho production)

### Bước 1: Tạo tài khoản SendGrid

1. Đăng ký tại sendgrid.com
2. Verify domain
3. Tạo API Key

### Bước 2: Set Environment Variables

```bash
export SENDGRID_API_KEY="your-sendgrid-api-key"
export SENDGRID_DOMAIN="yourdomain.com"
export BASE_URL="https://yourdomain.com"
```

### Bước 3: Cập nhật cấu hình

Uncomment phần SendGrid trong `config/environments/production.rb` và comment phần Gmail.

## 3. Amazon SES (Cho AWS)

### Bước 1: Setup SES

1. Tạo SES trong AWS Console
2. Verify domain/email
3. Tạo SMTP credentials

### Bước 2: Set Environment Variables

```bash
export AWS_REGION="us-east-1"
export SES_DOMAIN="yourdomain.com"
export SES_SMTP_USERNAME="your-ses-smtp-username"
export SES_SMTP_PASSWORD="your-ses-smtp-password"
export BASE_URL="https://yourdomain.com"
```

### Bước 3: Cập nhật cấu hình

Uncomment phần Amazon SES trong `config/environments/production.rb`.

## 4. Mailgun

### Bước 1: Setup Mailgun

1. Tạo tài khoản tại mailgun.com
2. Add domain
3. Lấy SMTP credentials

### Bước 2: Set Environment Variables

```bash
export MAILGUN_DOMAIN="yourdomain.com"
export MAILGUN_USERNAME="your-mailgun-username"
export MAILGUN_PASSWORD="your-mailgun-password"
export BASE_URL="https://yourdomain.com"
```

### Bước 3: Cập nhật cấu hình

Uncomment phần Mailgun trong `config/environments/production.rb`.

## 5. Kiểm tra cấu hình

### Test trong Rails console

```ruby
# SSH vào server production
rails console

# Test gửi email
user = User.first
UserMailer.confirmation_email(user).deliver_later
```

### Kiểm tra logs

```bash
tail -f log/production.log
```

## 6. Background Job (Khuyến nghị)

Để tránh block request khi gửi email, sử dụng background job:

### Cài đặt Sidekiq

```ruby
# Gemfile
gem 'sidekiq'
```

### Cấu hình trong production.rb

```ruby
config.active_job.queue_adapter = :sidekiq
```

### Sử dụng trong mailer

```ruby
# Thay vì deliver_later, sử dụng deliver_later
UserMailer.confirmation_email(user).deliver_later
```

## 7. Monitoring

### Kiểm tra email delivery

- Monitor logs: `tail -f log/production.log | grep "Mailer"`
- Sử dụng service monitoring (New Relic, DataDog)
- Setup email delivery tracking

### Rate Limiting

- Gmail: 500 emails/day (free), 2000 emails/day (paid)
- SendGrid: 100 emails/day (free), unlimited (paid)
- SES: 200 emails/day (free tier), scalable (paid)

## 8. Security

### Environment Variables

- Không commit credentials vào git
- Sử dụng .env files hoặc server environment variables
- Rotate credentials định kỳ

### SSL/TLS

- Luôn sử dụng STARTTLS
- Verify SSL certificates
- Monitor SSL expiration

## Troubleshooting

### Email không gửi được

1. Kiểm tra environment variables
2. Verify domain/email trong service provider
3. Check firewall settings
4. Review logs: `tail -f log/production.log`

### Email bị spam

1. Setup SPF, DKIM, DMARC records
2. Verify domain reputation
3. Use consistent from address
4. Avoid spam trigger words
