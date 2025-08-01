class Match < ApplicationRecord
  belongs_to :user
  belongs_to :target_user, class_name: 'User'
  has_one :chat_room, dependent: :destroy
  
  # ステータスの定義
  STATUSES = {
    'pending' => 0,
    'matched' => 1,
    'rejected' => 2,
    'blocked' => 3
  }.freeze
  
  validates :status, inclusion: { in: STATUSES.values }
  
  # ステータスメソッド
  def pending?
    status == 0
  end
  
  def matched?
    status == 1
  end
  
  def rejected?
    status == 2
  end
  
  def blocked?
    status == 3
  end
  
  def self.pending
    where(status: 0)
  end
  
  def self.matched
    where(status: 1)
  end
  
  def self.rejected
    where(status: 2)
  end
  
  def self.blocked
    where(status: 3)
  end
  
  # バリデーション
  validates :user_id, uniqueness: { scope: :target_user_id, message: "既にマッチリクエストが存在します" }
  validate :cannot_match_self
  
  # スコープ
  scope :mutual_matches, -> { where(status: :matched) }
  scope :pending_matches, -> { where(status: :pending) }
  
  # クラスメソッド
  def self.create_match_request(user, target_user)
    return false if user == target_user
    
    # 既存のマッチリクエストをチェック
    existing_match = find_by(user: user, target_user: target_user)
    return existing_match if existing_match
    
    # 相手からのマッチリクエストがあるかチェック
    reverse_match = find_by(user: target_user, target_user: user)
    
    if reverse_match && reverse_match.pending?
      # 相手からのリクエストがある場合、両方をマッチ状態にする
      reverse_match.update!(status: 1) # matched
      create!(user: user, target_user: target_user, status: 1) # matched
    else
      # 新しいマッチリクエストを作成
      create!(user: user, target_user: target_user, status: 0) # pending
    end
  end
  
  # インスタンスメソッド
  def mutual_match?
    return false unless matched?
    Match.exists?(user: target_user, target_user: user, status: 1) # matched
  end
  
  # マッチした時にチャットルームを作成
  def create_chat_room!
    return chat_room if chat_room.present?
    
    ChatRoom.create!(
      match: self,
      name: "#{user.name} & #{target_user.name}"
    )
  end
  
  # requester/receiver の定義
  def requester
    user
  end
  
  def receiver
    target_user
  end
  
  private
  
  def cannot_match_self
    errors.add(:target_user, "自分自身とはマッチングできません") if user_id == target_user_id
  end
end
