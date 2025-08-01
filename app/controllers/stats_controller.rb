class StatsController < ApplicationController
  include MatchStatsHelper
  
  def index
    # JSONファイルから統計データを読み込み、古い場合は再生成
    json_path = Rails.root.join('public', 'match_stats.json')
    
    if File.exist?(json_path)
      file_data = JSON.parse(File.read(json_path))
      last_generated = Time.parse(file_data['generated_at']) rescue 1.hour.ago
      
      # 1時間以上古い場合は再生成
      if last_generated < 1.hour.ago
        generate_fresh_stats
      end
      
      @stats = JSON.parse(File.read(json_path))
    else
      generate_fresh_stats
      @stats = JSON.parse(File.read(json_path)) if File.exist?(json_path)
    end
    
    @stats ||= default_stats
    
    # 画像データを初期化
    @images = {
      match_rate_chart: File.exist?(Rails.root.join('public', 'match_rate_chart.png')),
      monthly_trend_chart: File.exist?(Rails.root.join('public', 'monthly_trend_chart.png'))
    }
  end
  
  def generate_stats
    # 統計データを生成
    result = generate_match_statistics
    
    if result
      flash[:notice] = '統計データを更新しました'
      
      # 統計データ更新完了をURLパラメータで明示
      redirect_url = request.referer || root_path
      redirect_url += (redirect_url.include?('?') ? '&' : '?') + 'stats_updated=true'
      redirect_to redirect_url
    else
      flash[:alert] = '統計データの更新に失敗しました'
      redirect_back(fallback_location: root_path)
    end
  end
  
  private
  
  def generate_fresh_stats
    generate_match_statistics
  end
  
  def default_stats
    {
      'total_users' => User.count,
      'match_rate' => 0,
      'total_matches' => Match.count,
      'success_rate' => 0,
      'popular_skills' => [],
      'generated_at' => Time.current.iso8601
    }
  end
end
