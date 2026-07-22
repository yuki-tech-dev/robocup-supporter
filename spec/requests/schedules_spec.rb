require 'rails_helper'

RSpec.describe "Schedules", type: :request do
  let(:user) { FactoryBot.create(:user, password: "password", password_confirmation: "password") }

  before do
    post login_path, params: { email: user.email, password: "password" }
  end

  describe "GET /schedules/new" do
    it "returns http success" do
      get new_schedule_path
      expect(response).to have_http_status(:success)
    end

    it "タイトルが表示されること" do
      get new_schedule_path
      expect(response.body).to include("予定の新規登録")
    end
  end

  describe "POST /schedules" do
    let(:valid_params) do
      {
        schedule: {
          title: "磐田大会",
          start_time: "2026-08-01 13:30",
          end_time: "2026-08-01 16:30",
          location: "ワークぴあ",
          description: "全員参加の大会です"
        }
      }
    end

    let(:invalid_params) do
      { schedule: { title: "", start_time: "" } }
    end

    it "有効な情報の場合、予定が作成されトップページにリダイレクトされること" do
      expect do
        post schedules_path, params: valid_params
      end.to change(Schedule, :count).by(1)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("予定を登録しました")
    end

    it "不正な情報の場合、予定が作成されずエラーメッセージが表示されること" do
      expect do
        post schedules_path, params: invalid_params
      end.not_to change(Schedule, :count)
      expect(response.body).to include("予定の登録に失敗しました")
    end
  end
end
