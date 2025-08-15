class UserSettingDto
  include ActiveModel::Model

  attr_accessor :theme, :notifications_enabled, :language

  # Validations
  validates :theme, presence: true, inclusion: { in: %w[light dark] }
  validates :notifications_enabled, inclusion: { in: [true, false] }
  validates :language, presence: true, inclusion: { in: %w[vi en] }
end
