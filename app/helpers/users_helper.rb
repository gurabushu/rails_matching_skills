module UsersHelper
  def compatibility_score_with(user)
    return nil unless user_signed_in? && user != current_user
    
    # キャッシュキーを作成（ユーザーペアを一意に識別）
    cache_key = "compatibility_#{[current_user.id, user.id].sort.join('_')}"
    
    # キャッシュから取得を試行（24時間有効）
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      begin
        ai_service = AiMatchingService.new
        compatibility = ai_service.calculate_compatibility(current_user, user)
        compatibility[:score]
      rescue => e
        Rails.logger.error "Compatibility calculation failed: #{e.message}"
        # エラー時は50%のデフォルトスコアをキャッシュ
        50
      end
    end
  end
  
  def get_cached_compatibility_score(user)
    return nil unless user_signed_in? && user != current_user
    
    cache_key = "compatibility_#{[current_user.id, user.id].sort.join('_')}"
    Rails.cache.read(cache_key)
  end
  
  def compatibility_color_class(score)
    return 'compatibility-unknown' if score.nil?
    
    case score
    when 80..100
      'compatibility-excellent'
    when 60..79
      'compatibility-good'
    when 40..59
      'compatibility-fair'
    else
      'compatibility-low'
    end
  end
  
  def compatibility_text(score)
    return '分析中' if score.nil?
    
    case score
    when 80..100
      '非常に良い'
    when 60..79
      '良い'
    when 40..59
      '普通'
    else
      '要改善'
    end
  end
end
