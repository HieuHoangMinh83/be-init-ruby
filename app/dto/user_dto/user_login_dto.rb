# app/dto/user_dto/user_login_dto.rb
module UserDto
  class UserLoginDto
    include ActiveModel::Model

    attr_accessor :email, :password

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true
  end
end
