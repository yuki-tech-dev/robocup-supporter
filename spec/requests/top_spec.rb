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

  describe "GET /index（ログイン時）" do
    let(:user) { FactoryBot.create(:user, password: "password", password_confirmation: "password") }
    let!(:schedule) { FactoryBot.create(:schedule, title: "○○大会", start_time: 1.day.from_now) }

    before do
      post login_path, params: { email: user.email, password: "password" }
    end

    it "カレンダーが表示されること" do
      get "/"
      expect(response.body).to include("教室カレンダー")
    end

    it "直近の予定にスケジュールのタイトルが表示されること" do
      get "/"
      expect(response.body).to include("直近の予定")
      expect(response.body).to include(schedule.title)
    end
  end
end
