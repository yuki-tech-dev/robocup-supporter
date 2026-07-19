require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /users/new" do
    it "returns http success" do
      get new_user_path
      expect(response).to have_http_status(:success)
    end

    it "タイトルが表示されること" do
      get new_user_path
      expect(response.body).to include("ユーザー登録")
    end
  end

  describe "POST /users" do
    it "有効な情報の場合、ユーザーが作成されトップページにリダイレクトされること" do
      expect do
        post users_path, params: { user: attributes_for(:user) }
      end.to change(User, :count).by(1)
      expect(response).to redirect_to(root_path)
    end

    it "不正な情報の場合、ユーザーが作成されずエラーメッセージが表示されること" do
      expect do
        post users_path, params: { user: { name: "", email: "", password: "", password_confirmation: "" } }
      end.not_to change(User, :count)
      expect(response.body).to include("件のエラーが発生しました")
    end
  end
end
