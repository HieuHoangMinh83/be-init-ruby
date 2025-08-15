class User < ApplicationRecord
  include BCrypt
  has_one :user_setting, dependent: :destroy
  has_many :projects, dependent: :destroy, class_name: "Project", foreign_key: "owner_id"
  accepts_nested_attributes_for :user_setting, allow_destroy: true
  accepts_nested_attributes_for :projects, allow_destroy: true
  after_create :create_default_setting

  # Gán password và mã hóa trước khi lưu
  def password=(new_password)
    self[:password] = Password.create(new_password) if new_password.present?
  end

  private

  def create_default_setting
    create_user_setting if user_setting.nil?
  end
end
