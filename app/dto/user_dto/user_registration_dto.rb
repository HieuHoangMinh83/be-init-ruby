module UserDto
  class UserRegistrationDto
    include ActiveModel::Model

    attr_accessor :full_name, :email, :age, :raw_password, :password_confirmation, :role, :active

    validates :full_name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :age, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    validates :raw_password, presence: true, length: { minimum: 6 }
    validates :password_confirmation, presence: true
    validate :passwords_match

    def passwords_match
      errors.add(:password_confirmation, "không khớp") if raw_password != password_confirmation
    end

    def save
      return false unless valid?

      user = User.new(
        fullName: full_name,
        email: email,
        age: age,
        role: role || "user",
        active: active.nil? ? false : ActiveModel::Type::Boolean.new.cast(active),
      )
      user.password = raw_password
      if user.save
        true
      else
        user.errors.each do |attr, msg|
          errors.add(attr, msg)
        end
        false
      end
    end
  end
end
