require_dependency Rails.root.join("app", "dto", "user", "user_registration_dto")

class V1::UsersController < ApplicationController
  # GET /v1/users
  def index
    users = User.all
    render json: users
  end

  # GET /v1/users/:id
  def show
    user = User.find(params[:id])
    render json: user
  end

  # POST /v1/users

  # PUT /v1/users/:id
  def update
    user = User.find(params[:id])
    if user.update(user_params)
      render json: user
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /v1/users/:id
  def destroy
    user = User.find(params[:id])
    user.destroy
    head :no_content
  end

  # GET /v1/users/:id/details
  def details
    user = User.find(params[:id])
    render json: { user: user, notes: "Additional details here" }
  end

  # POST /v1/users/:id/activate
  def activate
    user = User.find(params[:id])
    user.update(active: true)
    render json: { message: "User activated", user: user }
  end

  # GET /v1/users/recent
  def recent
    recent_users = User.order(created_at: :desc).limit(5)
    render json: recent_users
  end

  # GET /v1/users/search?term=abc
  def search
    term = params[:term]
    results = User.where("full_name ILIKE ?", "%#{term}%")
    render json: results
  end

  # GET /v1/users/filtered
  def filtered
    results = User.where("active = ? AND age > ? OR email ILIKE ?", true, 25, "%gmail%")
                  .order(created_at: :desc)
                  .limit(10)
    render json: results
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :email, :age, :raw_password, :password_confirmation)
  end
end
