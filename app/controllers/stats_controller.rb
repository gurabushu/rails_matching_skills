class StatsController < ApplicationController
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
    
    # 画像ファイルの存在確認
    public_path = Rails.root.join('public')
    @images = {
      match_rate_chart: File.exist?(public_path.join('match_rate_chart.png')),
      monthly_trend_chart: File.exist?(public_path.join('monthly_trend_chart.png'))
    }
  end
  
  def generate_stats
    # Pythonスクリプトを実行して統計データを生成
    script_path = Rails.root.join('lib', 'tasks', 'scripts', 'generate_match_stats.py')
    python_path = Rails.root.join('.venv', 'bin', 'python')
    
    if File.exist?(python_path) && File.exist?(script_path)
      system("cd #{Rails.root} && #{python_path} #{script_path}")
      flash[:notice] = '統計データを更新しました'
      
      # 統計データ更新完了をURLパラメータで明示
      redirect_url = request.referer || root_path
      redirect_url += (redirect_url.include?('?') ? '&' : '?') + 'stats_updated=true'
      redirect_to redirect_url
    else
      flash[:alert] = 'Pythonスクリプトまたは仮想環境が見つかりません'
      redirect_back(fallback_location: root_path)
    end
  end
  
  private
  
  def generate_fresh_stats
    script_path = Rails.root.join('lib', 'tasks', 'scripts', 'generate_match_stats.py')
    python_path = Rails.root.join('.venv', 'bin', 'python')
    
    if File.exist?(python_path) && File.exist?(script_path)
      system("cd #{Rails.root} && #{python_path} #{script_path}")
    end
  end
  
  def default_stats
    {
      'total_users' => User.count,
      'match_rate' => 0,
      'total_matches' => Match.count,
      'success_rate' => 0,
      'generated_at' => Time.current.iso8601
    }
  end
end
