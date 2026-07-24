class Schedule < ApplicationRecord
  validates :title, length: { within: 3..30, allow_blank: true }, presence: true
  validates :start_time, presence: true
  validates :location, length: { maximum: 255 }
  validates :description, length: { maximum: 255 }
  validate :end_time_after_start_time

  private

  # end_timeが未入力（nil）の場合は保存できる必要があるためスキップ。
  # start_timeがpresence: trueで未入力の場合も、比較(end_time < start_time)で
  # nilとの比較エラーになるのを避けるため合わせてスキップする。
  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, :after_start_time) if end_time < start_time
  end
end
