module MatchStatsHelper
  def generate_match_statistics
    script_path = Rails.root.join('lib', 'scripts', 'generate_match_stats.py')
    venv_python = Rails.root.join('venv', 'bin', 'python')
    
    begin
      # 仮想環境のPythonを使用してスクリプトを実行
      python_command = File.exist?(venv_python) ? venv_python : 'python3'
      result = system("#{python_command} #{script_path}")
      
      if result
        # 生成された統計データを読み込み
        stats_path = Rails.root.join('public', 'match_stats.json')
        if File.exist?(stats_path)
          JSON.parse(File.read(stats_path))
        else
          nil
        end
      else
        nil
      end
    rescue => e
      Rails.logger.error "Match statistics generation failed: #{e.message}"
      nil
    end
  end

  def match_stats_available?
    chart1_path = Rails.root.join('public', 'match_rate_chart.png')
    chart2_path = Rails.root.join('public', 'monthly_trend_chart.png')
    stats_path = Rails.root.join('public', 'match_stats.json')
    
    File.exist?(chart1_path) && File.exist?(chart2_path) && File.exist?(stats_path)
  end

  def get_cached_match_stats
    stats_path = Rails.root.join('public', 'match_stats.json')
    
    if File.exist?(stats_path)
      begin
        stats = JSON.parse(File.read(stats_path))
        
        # 1時間以内のデータなら使用
        generated_at = Time.parse(stats['generated_at'])
        if Time.current - generated_at < 1.hour
          return stats
        end
      rescue => e
        Rails.logger.error "Failed to read cached stats: #{e.message}"
      end
    end
    
    # キャッシュが古いか存在しない場合は新規生成
    generate_match_statistics
  end
end
