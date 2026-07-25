class Material < ApplicationRecord
  validates :title, presence: true, length: { within: 2..30, allow_blank: true }
  validates :description, length: { maximum: 255 }
end
