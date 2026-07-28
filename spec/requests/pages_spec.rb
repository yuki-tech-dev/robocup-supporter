require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /terms" do
    it "returns http success" do
      get terms_path
      expect(response).to have_http_status(:success)
    end

    it "タイトルが表示されること" do
      get terms_path
      expect(response.body).to include("利用規約")
    end
  end

  describe "GET /privacy_policy" do
    it "returns http success" do
      get privacy_policy_path
      expect(response).to have_http_status(:success)
    end

    it "タイトルが表示されること" do
      get privacy_policy_path
      expect(response.body).to include("プライバシーポリシー")
    end
  end
end
