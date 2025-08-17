class Project < ApplicationRecord
  # has_many :objects, class_name: "object", foreign_key: "reference_id"
  has_many :tasks, dependent: :destroy
  belongs_to :user, class_name: "User", foreign_key: "owner_id"
  accepts_nested_attributes_for :tasks, allow_destroy: true
end
