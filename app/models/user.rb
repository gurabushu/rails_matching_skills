class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Active Storage: アバター画像
  has_one_attached :avatar_image

  validates :avatar_image, content_type: { in: %w[image/jpeg image/png image/gif],
                                         message: "は画像ファイル（JPEG、PNG、GIF）である必要があります" },
                          size: { less_than: 5.megabytes, message: "は5MB以下である必要があります" },
                          unless: :guest_user?

  validates :email, presence: true, uniqueness: true
  validates :encrypted_password, presence: true
  validates :description, length: { maximum: 300 }
  validates :hobbies, length: { maximum: 200 }
  validates :name, presence: true, length: { maximum: 50 }, unless: :guest_user?
  validates :skill, presence: true, length: { maximum: 50 }, unless: :guest_user?
  # validates :github, format: { with: /\Ahttps:\/\/github\.com\/[\w\-\.]+\z/, message: "はGitHubのURLの形式で入力してください（例：https://github.com/username）" }, allow_blank: true

  # マッチング関連のアソシエーション
  has_many :sent_matches, class_name: 'Match', foreign_key: 'user_id', dependent: :destroy
  has_many :received_matches, class_name: 'Match', foreign_key: 'target_user_id', dependent: :destroy
  
  # チャットとメッセージの関連
  has_many :messages, dependent: :destroy
  
  # 取引関連の関連
  has_many :client_deals, class_name: 'Deal', foreign_key: 'client_id', dependent: :destroy
  has_many :freelancer_deals, class_name: 'Deal', foreign_key: 'freelancer_id', dependent: :destroy
  
  # マッチした相手を取得
  has_many :matched_users, -> { where(matches: { status: 1 }) }, 
           through: :sent_matches, source: :target_user
  has_many :matched_by_users, -> { where(matches: { status: 1 }) }, 
           through: :received_matches, source: :user

  def guest_user?
    email == 'guest@example.com'
  end
  
  # マッチング関連のメソッド
  def sent_match_to?(target_user)
    sent_matches.exists?(target_user: target_user)
  end
  
  def received_match_from?(target_user)
    received_matches.exists?(user: target_user)
  end
  
  def matched_with?(target_user)
    Match.exists?(user: self, target_user: target_user, status: 1) ||
    Match.exists?(user: target_user, target_user: self, status: 1)
  end
  
  def pending_match_with?(target_user)
    sent_matches.where(status: 0).exists?(target_user: target_user) ||
    received_matches.where(status: 0).exists?(user: target_user)
  end
  
  def match_status_with(target_user)
    sent_match = sent_matches.find_by(target_user: target_user)
    received_match = received_matches.find_by(user: target_user)
    
    if (sent_match && sent_match.status == 1) || (received_match && received_match.status == 1)
      :matched
    elsif sent_match && sent_match.status == 0
      :sent_pending
    elsif received_match && received_match.status == 0
      :received_pending
    else
      :none
    end
  end
  
  def all_matches
    matched_users + matched_by_users
  end
  
  def all_deals
    client_deals + freelancer_deals
  end
  
  # チャットルームを取得
  def chat_rooms
    match_ids = (sent_matches.where(status: 1).pluck(:id) + received_matches.where(status: 1).pluck(:id)).uniq
    ChatRoom.where(match_id: match_ids)
  end

  # アバター画像のURLを取得（未設定の場合はデフォルト画像）
  def avatar_url(variant = :thumb)
    if avatar_image.attached?
      begin
        case variant
        when :thumb
          Rails.application.routes.url_helpers.rails_representation_path(
            avatar_image.variant(resize_to_fill: [120, 120]),
            only_path: true
          )
        when :small
          Rails.application.routes.url_helpers.rails_representation_path(
            avatar_image.variant(resize_to_fill: [50, 50]),
            only_path: true
          )
        when :nav
          Rails.application.routes.url_helpers.rails_representation_path(
            avatar_image.variant(resize_to_fill: [30, 30]),
            only_path: true
          )
        else
          Rails.application.routes.url_helpers.rails_blob_path(avatar_image, only_path: true)
        end
      rescue => e
        # VIPSエラーの場合は元画像を返す
        Rails.application.routes.url_helpers.rails_blob_path(avatar_image, only_path: true)
      end
    else
      '/default_avatar.svg'
    end
  rescue
    '/default_avatar.svg'
  end

  # アバター画像が設定されているかチェック
  def avatar_present?
    avatar_image.attached?
  end
end
