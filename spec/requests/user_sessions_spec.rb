require 'rails_helper'

RSpec.describe "UserSessions", type: :request do
  describe "GET /login" do
    it "returns http success" do
      get login_path
      expect(response).to have_http_status(:success)
    end

    it "タイトルが表示されること" do
      get login_path
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /login" do
    let(:user) { FactoryBot.create(:user, password: "password", password_confirmation: "password") }

    it "有効な情報の場合、ログインしトップページにリダイレクトされること" do
      post login_path, params: { email: user.email, password: "password" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("ログアウト")
    end

    it "不正な情報の場合、ログインに失敗しエラーメッセージが表示されること" do
      post login_path, params: { email: user.email, password: "wrong_password" }
      expect(response.body).to include("ログインに失敗しました")
    end
  end

  describe "DELETE /logout" do
    let(:user) { FactoryBot.create(:user, password: "password", password_confirmation: "password") }

    it "ログアウトしトップページにリダイレクトされること" do
      post login_path, params: { email: user.email, password: "password" }

      delete logout_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("ログアウトしました")
      expect(response.body).to include("新規登録")
    end
  end
end
