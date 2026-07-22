FactoryBot.define do
  factory :schedule do
    title { "磐田大会" }
    start_time { "2026-07-01 13:30:00" }
    end_time { "2026-07-01 16:30:00" }
    location { "ワークぴあ" }
    description { "全員参加の大会を開催します" }
  end
end
