class User < ApplicationRecord
  authenticates_with_sorcery!

  validates :password, length: { minimum: 3 }, confirmation: true, if: -> { new_record? || password.present? }
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true

  # NOTE: 位置引数スタイルを採用（キーワード引数スタイル `enum role: {...}` はRails 8.0で削除予定のため非推奨警告が出る）
  enum :role, { member: 0, staff: 1, admin: 2 }
end
