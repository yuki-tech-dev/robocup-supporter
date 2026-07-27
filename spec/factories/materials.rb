FactoryBot.define do
  factory :material do
    title { "操作マニュアル" }
    description { "ロボットの操作方法についての説明資料です" }

    after(:build) do |material|
      material.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
        filename: "sample.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
