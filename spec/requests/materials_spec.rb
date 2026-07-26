require 'rails_helper'

RSpec.describe "Materials", type: :request do
  let(:user) { FactoryBot.create(:user, password: "password", password_confirmation: "password") }

  before do
    post login_path, params: { email: user.email, password: "password" }
  end

  describe "GET /materials/new" do
    it "returns http success" do
      get new_material_path
      expect(response).to have_http_status(:success)
    end

    it "タイトルが表示されること" do
      get new_material_path
      expect(response.body).to include("資料の新規登録")
    end
  end

  describe "POST /materials" do
    let(:valid_params) do
      { material: { title: "操作マニュアル", description: "ロボットの操作方法についての説明資料です" } }
    end

    let(:invalid_params) do
      { material: { title: "" } }
    end

    it "有効な情報の場合、資料が作成されトップページにリダイレクトされること" do
      expect do
        post materials_path, params: valid_params
      end.to change(Material, :count).by(1)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("資料を登録しました")
    end

    it "不正な情報の場合、資料が作成されずエラーメッセージが表示されること" do
      expect do
        post materials_path, params: invalid_params
      end.not_to change(Material, :count)
      expect(response.body).to include("資料の登録に失敗しました")
    end
  end
end
