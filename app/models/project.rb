class Project < ApplicationRecord
  # has_many :objects, class_name: "object", foreign_key: "reference_id"

  belongs_to :user, class_name: "User", foreign_key: "owner_id"
end
