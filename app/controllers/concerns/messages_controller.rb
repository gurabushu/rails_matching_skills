class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat_room
  
  def create
    @message = @chat_room.messages.build(message_params)
    @message.user = current_user
    
    if @message.save
      redirect_to @chat_room, notice: 'メッセージを送信しました。'
    else
      redirect_to @chat_room, alert: 'メッセージの送信に失敗しました。'
    end
  end
  
  def download_file
    @message = @chat_room.messages.find(params[:id])
    
    if @message.file_attached?
      redirect_to rails_blob_path(@message.file, disposition: "attachment")
    else
      redirect_to @chat_room, alert: 'ファイルが見つかりません。'
    end
  end
  
  private
  
  def set_chat_room
    @chat_room = current_user.chat_rooms.find(params[:chat_room_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to chat_rooms_path, alert: 'チャットルームが見つかりません。'
  end
  
  def message_params
    params.require(:message).permit(:content, :file)
  end
end
