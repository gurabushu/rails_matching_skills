# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# テスト用ユーザーの作成
puts "Creating sample users..."

# ユーザー1: デザイナー
user1 = User.find_or_create_by(email: 'designer@example.com') do |user|
  user.password = 'password123'
  user.name = '山田太郎'
  user.skill = 'UIデザイン'
  user.description = 'Web/アプリのUIデザインが得意です。ユーザビリティを重視したデザインを心がけています。'
end

# ユーザー2: エンジニア
user2 = User.find_or_create_by(email: 'engineer@example.com') do |user|
  user.password = 'password123'
  user.name = '佐藤花子'
  user.skill = 'Ruby on Rails'
  user.description = 'バックエンド開発が専門です。Rails歴5年、スケーラブルなWebアプリケーション開発経験あり。'
end

# ユーザー3: マーケター
user3 = User.find_or_create_by(email: 'marketer@example.com') do |user|
  user.password = 'password123'
  user.name = '田中一郎'
  user.skill = 'デジタルマーケティング'
  user.description = 'SNSマーケティング、SEO、広告運用などデジタルマーケティング全般に対応可能です。'
end

# ユーザー4: ライター
user4 = User.find_or_create_by(email: 'writer@example.com') do |user|
  user.password = 'password123'
  user.name = '鈴木次郎'
  user.skill = 'コンテンツライティング'
  user.description = 'Web記事、ブログ、コピーライティングが得意です。SEOを意識した文章作成も可能。'
end

puts "Created #{User.count} users"

# マッチの作成（デモ用）
puts "Creating sample matches..."

# ユーザー1とユーザー2がマッチ済み
if user1 && user2
  match1 = Match.find_or_create_by(user: user1, target_user: user2) do |match|
    match.status = 1 # matched
  end
  
  match2 = Match.find_or_create_by(user: user2, target_user: user1) do |match|
    match.status = 1 # matched
  end
  
  # チャットルームを作成
  if match1 && !match1.chat_room
    chat_room = match1.create_chat_room!
    
    # サンプルメッセージを追加
    Message.create!(
      chat_room: chat_room,
      user: user1,
      content: "こんにちは！UIデザインのお仕事でお困りのことがあれば、お気軽にご相談ください。"
    )
    
    Message.create!(
      chat_room: chat_room,
      user: user2,
      content: "ありがとうございます！実は新しいWebアプリのデザインを考えているところでした。"
    )
    
    Message.create!(
      chat_room: chat_room,
      user: user1,
      content: "それは素晴らしいですね！どのようなアプリですか？詳細を教えていただけますか？"
    )
  end
end

# ユーザー3からユーザー4へのマッチリクエスト（pending）
if user3 && user4
  Match.find_or_create_by(user: user3, target_user: user4) do |match|
    match.status = 0 # pending
  end
end

puts "Created sample matches and messages"
puts "Sample data creation completed!"
puts ""
puts "Test accounts:"
puts "  Designer: designer@example.com / password123"
puts "  Engineer: engineer@example.com / password123"
puts "  Marketer: marketer@example.com / password123"
puts "  Writer: writer@example.com / password123"
