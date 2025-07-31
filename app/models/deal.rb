class Deal < ApplicationRecord
  belongs_to :match
  belongs_to :client, class_name: 'User'
  belongs_to :freelancer, class_name: 'User'
  
  validates :title, presence: true
  validates :status, presence: true
  
  STATUSES = {
    'pending' => 0,      # 提案中
    'accepted' => 1,     # 受諾済み
    'in_progress' => 2,  # 作業中
    'completed' => 3,    # 完了
    'cancelled' => 4     # キャンセル
  }.freeze
  
  def status_name
    STATUSES.key(status) || 'unknown'
  end
  
  def pending?
    status == STATUSES['pending']
  end
  
  def accepted?
    status == STATUSES['accepted']
  end
  
  def in_progress?
    status == STATUSES['in_progress']
  end
  
  def completed?
    status == STATUSES['completed']
  end
  
  def cancelled?
    status == STATUSES['cancelled']
  end
  
  def can_accept?
    pending?
  end
  
  def can_start?
    accepted?
  end
  
  def can_complete?
    in_progress?
  end
  
  def can_cancel?
    pending? || accepted? || in_progress?
  end
end
