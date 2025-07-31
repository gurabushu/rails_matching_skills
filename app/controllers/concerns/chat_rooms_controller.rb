class ChatRoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat_room, only: [:show]
  
  def index
    @chat_rooms = current_user.chat_rooms.includes(:match, :messages)
  end

  def show
    @message = Message.new
    @messages = @chat_room.messages.includes(:user).order(:created_at)
    
    # 自分以外のメッセージを既読にする
    @chat_room.messages.where.not(user: current_user).unread.update_all(read_at: Time.current)
  end
  
  private
  
  def set_chat_room
    @chat_room = current_user.chat_rooms.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # チャットルームが見つからない場合、マッチが存在すれば作成
    match_ids = current_user.sent_matches.where(status: 1).pluck(:id) + 
                current_user.received_matches.where(status: 1).pluck(:id)
    match = Match.find_by(id: params[:id]) if match_ids.include?(params[:id].to_i)
    
    if match
      @chat_room = match.create_chat_room!
    else
      redirect_to chat_rooms_path, alert: 'チャットルームが見つかりません。'
    end
  end
end
