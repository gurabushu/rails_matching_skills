// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// AI診断結果のキャッシュ
let compatibilityCache = new Map();

// AI診断ボタンクリック時の処理
window.showCompatibilityScore = function(button, userId) {
  const section = button.closest('.ai-compatibility-section');
  const scoreElement = section.querySelector('.compatibility-score');
  
  // ボタンを無効化
  button.disabled = true;
  button.innerHTML = '<i class="ai-icon">🤖</i> 分析中...';
  
  // スコア表示エリアを表示
  scoreElement.style.display = 'block';
  
  // キャッシュから取得を試行
  if (compatibilityCache.has(userId)) {
    const cachedScore = compatibilityCache.get(userId);
    updateCompatibilityDisplay(scoreElement, cachedScore);
    button.style.display = 'none';
    return;
  }
  
  // APIから取得
  loadCompatibilityScore(userId, scoreElement, button);
};

async function loadCompatibilityScore(userId, scoreElement, button) {
  try {
    const response = await fetch(`/matches/compatibility_check`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        user_id: userId
      })
    });
    
    if (response.ok) {
      const data = await response.json();
      const score = data.compatibility_score;
      
      // キャッシュに保存
      compatibilityCache.set(userId, score);
      
      // 表示を更新
      updateCompatibilityDisplay(scoreElement, score);
      
      // ボタンを非表示
      button.style.display = 'none';
    } else {
      console.error('Failed to load compatibility score');
      showCompatibilityError(scoreElement, button);
    }
  } catch (error) {
    console.error('Error loading compatibility score:', error);
    showCompatibilityError(scoreElement, button);
  }
}

function updateCompatibilityDisplay(scoreElement, score) {
  const detailsElement = scoreElement.querySelector('.compatibility-details');
  const colorClass = getCompatibilityColorClass(score);
  const text = getCompatibilityText(score);
  
  // 既存のカラークラスを削除
  scoreElement.classList.remove('compatibility-unknown', 'compatibility-excellent', 
                               'compatibility-good', 'compatibility-fair', 'compatibility-low');
  
  // 新しいカラークラスを追加
  scoreElement.classList.add(colorClass);
  
  // 内容を更新
  detailsElement.innerHTML = `
    <span class="score-percentage">${score}%</span>
    <span class="score-text">(${text})</span>
  `;
}

function showCompatibilityError(scoreElement, button) {
  const detailsElement = scoreElement.querySelector('.compatibility-details');
  detailsElement.innerHTML = '<span class="score-error">分析に失敗しました</span>';
  
  // ボタンを再度有効化
  button.disabled = false;
  button.innerHTML = '<i class="ai-icon">🤖</i> 再試行';
}

function getCompatibilityColorClass(score) {
  if (score >= 80) return 'compatibility-excellent';
  if (score >= 60) return 'compatibility-good';
  if (score >= 40) return 'compatibility-fair';
  return 'compatibility-low';
}

function getCompatibilityText(score) {
  if (score >= 80) return '非常に良い';
  if (score >= 60) return '良い';
  if (score >= 40) return '普通';
  return '要改善';
}
