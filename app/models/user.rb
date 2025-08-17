class User < ApplicationRecord
  include BCrypt
  has_one :user_setting, dependent: :destroy
  has_many :projects, dependent: :destroy, class_name: "Project", foreign_key: "owner_id"
  accepts_nested_attributes_for :user_setting, allow_destroy: true
  accepts_nested_attributes_for :projects, allow_destroy: true

  # Gán password và mã hóa trước khi lưu
  def password=(new_password)
    self[:password] = Password.create(new_password) if new_password.present?
  end

  private
end
