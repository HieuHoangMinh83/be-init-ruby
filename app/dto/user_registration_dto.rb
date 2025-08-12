class UserRegistrationDto
  include ActiveModel::Model
  include ActiveModel::Attributes
  attr_accessor :full_name, :email, :password

  # validate value sau khi ép kiểu (kiểu khi hứng )

  attribute :full_name, :string
  attribute :email, :string
  attribute :password, :string
  # validate value từ api
  validates :full_name, presence: true # không được null
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 } # độ ngắn tối thiểu,
end
