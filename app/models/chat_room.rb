class ChatRoom < ApplicationRecord
  belongs_to :match
  has_many :messages, dependent: :destroy
  
  validates :name, presence: true
  validates :match_id, uniqueness: true
  
  def participants
    [match.user, match.target_user]
  end
  
  def other_participant(current_user)
    participants.find { |user| user != current_user }
  end
  
  def last_message
    messages.order(created_at: :desc).first
  end
  
  def unread_messages_count(user)
    messages.where(user: participants.reject { |u| u == user }, read_at: nil).count
  end
end
