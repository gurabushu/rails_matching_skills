module MatchStatsHelper
  def generate_match_statistics
    begin
      # データベースから統計データを生成
      stats = calculate_match_statistics
      
      # JSONファイルに保存
      stats_path = Rails.root.join('public', 'match_stats.json')
      File.write(stats_path, stats.to_json)
      
      stats
    rescue => e
      Rails.logger.error "Match statistics generation failed: #{e.message}"
      nil
    end
  end
  
  private
  
  def calculate_match_statistics
    # 総ユーザー数（ゲストユーザーを除く）
    total_users = User.where.not(email: 'guest@example.com').count
    
    # マッチング済みユーザー数
    matched_user_ids = Match.where(status: 1).pluck(:user_id, :target_user_id).flatten.uniq
    matched_users = matched_user_ids.count
    
    # 総マッチ数
    total_matches = Match.where(status: 1).count
    
    # アクティブな取引数
    active_deals = Deal.where(status: [0, 1, 2]).count
    
    # 完了した取引数
    completed_deals = Deal.where(status: 3).count
    
    # マッチ率を計算
    match_rate = total_users > 0 ? (matched_users.to_f / total_users * 100).round(1) : 0
    success_rate = (active_deals + completed_deals) > 0 ? (completed_deals.to_f / (active_deals + completed_deals) * 100).round(1) : 0
    
    # 人気スキル（上位5位）
    popular_skills = User.where.not(email: 'guest@example.com')
                        .where.not(skill: [nil, ''])
                        .group(:skill)
                        .order(Arel.sql('COUNT(*) DESC'))
                        .limit(5)
                        .count
                        .map { |skill, count| { skill: skill, count: count } }
    
    {
      total_users: total_users,
      match_rate: match_rate,
      total_matches: total_matches,
      success_rate: success_rate,
      popular_skills: popular_skills,
      generated_at: Time.current.iso8601
    }
  end

  def match_stats_available?
    stats_path = Rails.root.join('public', 'match_stats.json')
    File.exist?(stats_path)
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
