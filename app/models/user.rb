class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, presence: true, uniqueness: true
  validates :encrypted_password, presence: true
  validates :description, length: { maximum: 300 }
  validates :name, presence: true, length: { maximum: 50 }, unless: :guest_user?
  validates :skill, presence: true, length: { maximum: 50 }, unless: :guest_user?

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
end
