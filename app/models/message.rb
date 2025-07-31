class Message < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user
  
  has_one_attached :file
  
  validates :content, presence: true, unless: :file_attached?
  validate :content_or_file_present
  
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  
  def read?
    read_at.present?
  end
  
  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
  
  def file_attached?
    file.attached?
  end
  
  def file_name
    file.filename.to_s if file_attached?
  end
  
  def file_size
    ActiveSupport::NumberHelper.number_to_human_size(file.byte_size) if file_attached?
  end
  
  def file_type
    file.content_type if file_attached?
  end
  
  def image?
    file_attached? && file.content_type.start_with?('image/')
  end
  
  private
  
  def content_or_file_present
    if content.blank? && !file_attached?
      errors.add(:base, 'メッセージまたはファイルのいずれかが必要です')
    end
  end
end
