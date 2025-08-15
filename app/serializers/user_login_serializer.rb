class UserLoginSerializer < ActiveModel::Serializer
  attributes :email, :full_name, :role, :age, :created_at

  def full_name
    object.fullName
  end
end
