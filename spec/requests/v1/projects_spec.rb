require "rails_helper"

RSpec.describe "V1::Project", type: :request do
  before do
    # chạy trước MỖI it
    @user = create(:user)
    @token = JwtService.encode(user_id: @user.id)
  end

  describe "GET /index" do
    context "khi có token hợp lệ" do
      it "trả về danh sách users" do
        get "/users", headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
      end
    end

    context "khi thiếu token" do
      it "trả về 401" do
        get "/users"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  describe "Post /create" do
    context "khi có token hợp lệ" do
      it "trả về danh sách users" do
        get "/users", headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
      end
    end

    context "khi thiếu token" do
      it "trả về 401" do
        get "/users"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  describe "Put /update" do
    context "khi có token hợp lệ" do
      it "trả về danh sách users" do
        get "/users", headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
      end
    end

    context "khi thiếu token" do
      it "trả về 401" do
        get "/users"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  describe "DELETE /destroy" do
    context "khi có token hợp lệ" do
      it "trả về danh sách users" do
        get "/users", headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
      end
    end

    context "khi thiếu token" do
      it "trả về 401" do
        get "/users"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  describe "Get /own_project" do
    context "khi có token hợp lệ" do
      it "trả về danh sách users" do
        get "/users", headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
      end
    end

    context "khi thiếu token" do
      it "trả về 401" do
        get "/users"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
