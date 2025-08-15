class ProjectDto
  include ActiveModel::Model

  attr_accessor :name, :description

  # Validations
  validates :name, presence: true
end
