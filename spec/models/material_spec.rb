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

  it "ファイルが添付されていない場合、無効になること" do
    material = Material.new(title: "操作マニュアル", description: "ロボットの操作方法についての説明資料です")
    expect(material).to be_invalid
    expect(material.errors[:file]).to include("を選択してください")
  end

  it "対応していないファイル形式の場合、無効になること" do
    material = FactoryBot.build(:material)
    material.file.attach(io: StringIO.new("dummy"), filename: "sample.txt", content_type: "text/plain")
    expect(material).to be_invalid
    expect(material.errors[:file]).to include("は対応していないファイル形式です（PDF, JPEG, PNGのみ可）")
  end

  it "ファイルサイズが10MBを超える場合、無効になること" do
    material = FactoryBot.build(:material)
    material.file.attach(io: StringIO.new("dummy"), filename: "sample.pdf", content_type: "application/pdf")
    allow(material.file.blob).to receive(:byte_size).and_return(11.megabytes)
    expect(material).to be_invalid
    expect(material.errors[:file]).to include("のサイズが大きすぎます（10MB以下にしてください）")
  end
end
