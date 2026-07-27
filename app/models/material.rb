class Material < ApplicationRecord
  has_one_attached :file
  validate :validate_file
  validates :title, presence: true, length: { within: 2..30, allow_blank: true }
  validates :description, length: { maximum: 255 }

  private

  def validate_file
    unless file.attached?
      errors.add(:file, "を選択してください")
      return
    end

    acceptable_types = [ "application/pdf", "image/jpeg", "image/png" ]

    # サイズチェック（10MB以下）
    if file.blob.byte_size > 10.megabytes
      errors.add(:file, "のサイズが大きすぎます（10MB以下にしてください）")
    end

    # 形式チェック
    unless acceptable_types.include?(file.blob.content_type)
      errors.add(:file, "は対応していないファイル形式です（PDF, JPEG, PNGのみ可）")
    end
  end
end
