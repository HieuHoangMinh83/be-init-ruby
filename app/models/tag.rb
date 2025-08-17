class Tag < ApplicationRecord
  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags
  accepts_nested_attributes_for :task_tags, allow_destroy: true
end
