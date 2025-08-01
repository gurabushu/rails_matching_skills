class DealsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deal, only: [:show, :edit, :update, :accept, :start, :complete, :cancel]
  before_action :set_match, only: [:new, :create]
  
  def index
    @client_deals = current_user.client_deals.includes(:match, :freelancer)
    @freelancer_deals = current_user.freelancer_deals.includes(:match, :client)
  end

  def show
  end

  def new
    @deal = @match.deals.build
    # マッチの相手ユーザーを設定
    @user = @match.user == current_user ? @match.target_user : @match.user
  end

  def create
    @deal = @match.deals.build(deal_params)
    @deal.client = current_user
    # マッチの相手を取得
    @deal.freelancer = @match.user == current_user ? @match.target_user : @match.user
    @user = @deal.freelancer  # ビューで使用するための変数
    @deal.status = Deal::STATUSES['pending']
    
    if @deal.save
      redirect_to @deal, notice: 'つながりを提案しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @deal.update(deal_params)
      redirect_to @deal, notice: 'つながりを更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def accept
    if @deal.can_accept? && @deal.freelancer == current_user
      @deal.update!(status: Deal::STATUSES['accepted'])
      redirect_to @deal, notice: 'つながりを受諾しました。'
    else
      redirect_to @deal, alert: 'つながりを受諾できませんでした。'
    end
  end
  
  def start
    if @deal.can_start? && @deal.client == current_user
      @deal.update!(status: Deal::STATUSES['in_progress'])
      redirect_to @deal, notice: 'つながりを開始しました。'
    else
      redirect_to @deal, alert: 'つながりを開始できませんでした。'
    end
  end
  
  def complete
    if @deal.can_complete? && @deal.client == current_user
      @deal.update!(status: Deal::STATUSES['completed'])
      redirect_to @deal, notice: 'つながりを完了しました。'
    else
      redirect_to @deal, alert: 'つながりを完了できませんでした。'
    end
  end
  
  def cancel
    if @deal.can_cancel?
      @deal.update!(status: Deal::STATUSES['cancelled'])
      redirect_to @deal, notice: 'つながりをキャンセルしました。'
    else
      redirect_to @deal, alert: 'つながりをキャンセルできませんでした。'
    end
  end
  
  private
  
  def set_deal
    @deal = Deal.joins(:match).where(
      match: { id: current_user.sent_matches.pluck(:id) + current_user.received_matches.pluck(:id) }
    ).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to deals_path, alert: '技術スキル交換が見つかりません。'
  end
  
  def set_match
    match_ids = current_user.sent_matches.matched.pluck(:id) + current_user.received_matches.matched.pluck(:id)
    @match = Match.find(params[:match_id]) if params[:match_id]
    
    unless @match && match_ids.include?(@match.id)
      redirect_to matches_path, alert: 'マッチしているエンジニアとのみ技術スキル交換を作成できます。'
    end
  end
  
  def deal_params
    params.require(:deal).permit(:title, :description, :deadline)
  end
end
