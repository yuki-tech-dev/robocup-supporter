require 'rails_helper'

RSpec.describe "Tops", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "ヘッダーにアプリ名が表示されること" do
      get "/"
      expect(response.body).to include("RoboCup Supporter")
    end

    it "ヘッダーにログインが表示されること" do
      get "/"
      expect(response.body).to include("ログイン")
    end

    it "ヘッダーに新規登録が表示されること" do
      get "/"
      expect(response.body).to include("新規登録")
    end
  end
end
