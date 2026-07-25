require 'rails_helper'

RSpec.describe Material, type: :model do
  it "factoryのデフォルト属性が有効であること" do
    material = FactoryBot.build(:material)
    expect(material).to be_valid
  end

  it "titleが未入力の場合、presenceのエラーのみで無効になること" do
    material = FactoryBot.build(:material, title: "")
    expect(material).to be_invalid
    expect(material.errors[:title]).to eq([ "を入力してください" ])
  end

  it "titleが2文字未満の場合、lengthのエラーで無効になること" do
    material = FactoryBot.build(:material, title: "a")
    expect(material).to be_invalid
    expect(material.errors[:title]).to include("は2文字以上で入力してください")
  end
end
