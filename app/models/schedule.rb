class Schedule < ApplicationRecord
  validates :title, length: { within: 3..30, allow_blank: true }, presence: true
  validates :start_time, presence: true
  validates :location, length: { maximum: 255 }
  validates :description, length: { maximum: 255 }
end
