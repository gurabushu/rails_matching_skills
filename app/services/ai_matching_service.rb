class AiMatchingService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY']) if valid_api_key?
  end

  def calculate_compatibility(user1, user2)
    # APIキーが無効な場合はデフォルト値を返す
    unless valid_api_key?
      return default_compatibility_response(user1, user2)
    end

    prompt = build_compatibility_prompt(user1, user2)
    
    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: "あなたは経験豊富なエンジニアキャリアコンサルタントです。2人のエンジニアのスキルや経験、興味を分析し、プロジェクトやキャリア面でのマッチング相性を評価してください。"
          },
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 800,
        temperature: 0.7
      }
    )

    parse_compatibility_response(response.dig("choices", 0, "message", "content"))
  rescue => e
    Rails.logger.error "AI Matching Error: #{e.message}"
    default_compatibility_result
  end

  def suggest_matches_for(user, candidates_limit: 5)
    potential_users = User.where.not(id: user.id)
                         .where.not(email: 'guest@example.com') # ゲストユーザーを除外
                         .limit(10)

    matches = potential_users.map do |candidate|
      compatibility = calculate_compatibility(user, candidate)
      {
        user: candidate,
        compatibility_score: compatibility[:score],
        reasons: compatibility[:reasons],
        collaboration_potential: compatibility[:collaboration_potential]
      }
    end

    matches.sort_by { |match| -match[:compatibility_score] }.first(candidates_limit)
  end

  private

  def build_compatibility_prompt(user1, user2)
    <<~PROMPT
      以下の2人のエンジニアの相性を分析してください：

      【エンジニア A】
      名前: #{user1.name}
      スキル: #{user1.skill}
      趣味・興味: #{user1.hobbies}

      【エンジニア B】
      名前: #{user2.name}
      スキル: #{user2.skill}
      趣味・興味: #{user2.hobbies}

      以下の観点で分析し、JSON形式で回答してください：

      {
        "compatibility_score": [0-100の数値],
        "reasons": ["相性が良い理由1", "理由2", "理由3"],
        "collaboration_potential": "具体的な協力可能性の説明",
        "skill_synergy": "スキルの相乗効果について",
        "growth_opportunities": "お互いの成長機会について"
      }
    PROMPT
  end

  def parse_compatibility_response(response)
    begin
      # JSONの抽出を試行
      json_match = response.match(/\{[\s\S]*\}/)
      if json_match
        result = JSON.parse(json_match[0])
        {
          score: result['compatibility_score'] || 50,
          reasons: result['reasons'] || ['相性を分析中です'],
          collaboration_potential: result['collaboration_potential'] || '相性の良い可能性があります',
          skill_synergy: result['skill_synergy'] || 'スキルの相乗効果があります',
          growth_opportunities: result['growth_opportunities'] || 'お互いの成長機会があります'
        }
      else
        default_compatibility_result
      end
    rescue JSON::ParserError
      default_compatibility_result
    end
  end

  def default_compatibility_result
    {
      score: 50,
      reasons: ['AIによる分析が現在利用できません'],
      collaboration_potential: '詳細な分析を後ほど提供します',
      skill_synergy: '分析中です',
      growth_opportunities: '分析中です'
    }
  end

  private

  def valid_api_key?
    api_key = ENV['OPENAI_API_KEY']
    api_key.present? && api_key.start_with?('sk-') && api_key.length > 20
  end

  def default_compatibility_response(user1, user2)
    # APIキーが無効な場合のデフォルトレスポンス
    score = rand(40..80) # ランダムな相性スコア
    {
      score: score,
      reasons: [
        "#{user1.name}さんと#{user2.name}さんのスキル分析",
        'AI分析は現在メンテナンス中です',
        '手動での詳細分析をお勧めします'
      ],
      collaboration_potential: 'プロフィールを直接確認してください',
      skill_synergy: 'お互いのスキルについて直接話し合うことをお勧めします',
      growth_opportunities: '詳細な分析は後日提供予定です'
    }
  end
end
