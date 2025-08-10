class V1::User::UserLoginSerializer < ActiveModel::Serializer
  attributes :id, :email, :full_name, :role, :active

  def full_name
    object.fullName # Nếu DB của bạn là fullName, map về full_name cho JSON
  end
end
