class UsersController < ApplicationController
  include MatchStatsHelper
  before_action :authenticate_user!, except: [:index, :show, :guest_sign_in]
  
  def index
    @users = User.all
    
    # 検索機能
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @users = @users.where(
        "LOWER(name) LIKE ? OR LOWER(skill) LIKE ? OR LOWER(description) LIKE ?", 
        search_term, search_term, search_term
      )
    end
    
    # スキルフィルター
    if params[:skill_filter].present?
      @users = @users.where("LOWER(skill) LIKE ?", "%#{params[:skill_filter].downcase}%")
    end
    
    # 並び順
    case params[:sort]
    when 'name'
      @users = @users.order(:name)
    when 'skill'
      @users = @users.order(:skill)
    when 'newest'
      @users = @users.order(created_at: :desc)
    when 'oldest'
      @users = @users.order(created_at: :asc)
    else
      @users = @users.order(created_at: :desc)
    end
    
    # 重複するスキルを取得（フィルター用）
    @available_skills = User.distinct.pluck(:skill).compact.reject(&:blank?).sort
    
    # 統計データの自動更新（1時間に1回）
    ensure_fresh_stats
  end

  def guest_sign_in
    # ゲストユーザーを最小限の情報で作成
    guest_user = User.find_or_create_by(email: 'guest@example.com') do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = 'ゲストユーザー'
      user.skill = ''  # スキル情報は空にする
      user.description = ''  # 説明も空にする
    end
    
    sign_in guest_user
    # 直接スキル一覧画面へリダイレクト
    redirect_to users_path, notice: 'ゲストユーザーとしてログインしました。スキル一覧を確認してください。'
  end

  def show
    # IDが数値でない場合はルートにリダイレクト
    unless params[:id].to_s.match?(/\A\d+\z/)
      redirect_to root_path, alert: "無効なユーザーIDです。"
      return
    end
    
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "ユーザーが見つかりません。"
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to @user, notice: "ユーザー情報が更新されました。"
    else
      render :edit
    end
  end

    def guest_login
      user = User.find_or_create_by(email: 'guest@example.com') do |u|
        u.password = SecureRandom.hex(10)
        u.name = "ゲストユーザー"
      end
      sign_in user
      redirect_to root_path, notice: "ゲストユーザーとしてログインしました。"
    end

    def update_skill   
        @user = User.find(params[:id])  
        if @user.update(user_skill_params)
          redirect_to @user, notice: "スキルが更新されました。"
        else
          render :edit
        end
    end

    def destroy 
        @user = User.find(params[:id])      
        if @user.destroy
          redirect_to root_path, notice: "ユーザーが削除されました。"
        else
          redirect_to @user, alert: "ユーザーの削除に失敗しました。"
        end
    end

  private

  def user_params
    params.require(:user).permit(:name, :skill, :description, :img)
  end

  def user_skill_params
    params.require(:user).permit(:skill)
  end
  
  def ensure_fresh_stats
    json_path = Rails.root.join('public', 'match_stats.json')
    
    if File.exist?(json_path)
      file_data = JSON.parse(File.read(json_path))
      last_generated = Time.parse(file_data['generated_at']) rescue 2.hours.ago
      
      # 1時間以上古い場合は再生成
      if last_generated < 1.hour.ago
        generate_stats_async
      end
    else
      generate_stats_async
    end
  end
  
  def generate_stats_async
    # バックグラウンドで統計データを生成
    Thread.new do
      generate_match_statistics
    end
  end

end
