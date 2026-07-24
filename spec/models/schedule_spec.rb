require 'rails_helper'

RSpec.describe Schedule, type: :model do
  it "factoryのデフォルト属性が有効であること" do
    schedule = FactoryBot.build(:schedule)
    expect(schedule).to be_valid
  end

  it "end_timeがstart_timeより前の場合、無効であること" do
    schedule = FactoryBot.build(:schedule, start_time: "2026-08-01 14:38", end_time: "2026-07-31 23:35")
    expect(schedule).to be_invalid
    expect(schedule.errors[:end_time]).to include("は開始日時より後の日時にしてください")
  end

  it "end_timeが未入力(nil)の場合、有効であること" do
    schedule = FactoryBot.build(:schedule, end_time: nil)
    expect(schedule).to be_valid
  end
end
