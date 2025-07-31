class MatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:create, :destroy]
  
  def index
    @sent_matches = current_user.sent_matches.includes(:target_user)
    @received_matches = current_user.received_matches.includes(:user)
    @matched_users = current_user.all_matches.uniq
  end

  def create
    if @target_user == current_user
      redirect_back(fallback_location: root_path, alert: '自分自身にはいいねを送れません。')
      return
    end
    
    begin
      match = Match.create_match_request(current_user, @target_user)
      
      if match.persisted?
        if match.matched?
          redirect_back(fallback_location: root_path, notice: "#{@target_user.name}さんとマッチしました！🎉")
        else
          redirect_back(fallback_location: root_path, notice: "#{@target_user.name}さんにいいねを送りました！")
        end
      else
        redirect_back(fallback_location: root_path, alert: 'マッチリクエストの送信に失敗しました。')
      end
    rescue => e
      redirect_back(fallback_location: root_path, alert: 'エラーが発生しました。')
    end
  end

  def destroy
    match = current_user.sent_matches.find_by(target_user: @target_user)
    if match
      match.destroy
      redirect_back(fallback_location: root_path, notice: 'いいねを取り消しました。')
    else
      redirect_back(fallback_location: root_path, alert: 'マッチリクエストが見つかりません。')
    end
  end
  
  # 受信したマッチリクエストを承認
  def accept
    @match = current_user.received_matches.find(params[:id])
    
    if @match.update(status: 1) # matched
      # 相手側のマッチも作成
      reverse_match = Match.create!(user: current_user, target_user: @match.user, status: 1) # matched
      
      # チャットルームを作成
      chat_room = @match.create_chat_room!
      
      redirect_to matches_path, notice: "#{@match.user.name}さんとマッチしました！🎉"
    else
      redirect_to matches_path, alert: 'マッチの承認に失敗しました。'
    end
  end
  
  # 受信したマッチリクエストを拒否
  def reject
    @match = current_user.received_matches.find(params[:id])
    
    if @match.update(status: 2) # rejected
      redirect_to matches_path, notice: 'マッチリクエストを拒否しました。'
    else
      redirect_to matches_path, alert: 'マッチリクエストの拒否に失敗しました。'
    end
  end
  
  private
  
  def set_user
    @target_user = User.find(params[:user_id])
  end
end
