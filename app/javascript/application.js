// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// AI相性診断の非同期読み込み
document.addEventListener('DOMContentLoaded', function() {
  const compatibilityScores = document.querySelectorAll('.compatibility-score');
  
  compatibilityScores.forEach(scoreElement => {
    const loadingElement = scoreElement.querySelector('.score-loading');
    if (loadingElement) {
      const userId = scoreElement.closest('.user-card').dataset.userId;
      if (userId) {
        loadCompatibilityScore(userId, scoreElement);
      }
    }
  });
});

async function loadCompatibilityScore(userId, scoreElement) {
  try {
    const response = await fetch(`/matches/${userId}/compatibility_check`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    });
    
    if (response.ok) {
      const data = await response.json();
      updateCompatibilityDisplay(scoreElement, data.compatibility_score);
    } else {
      console.error('Failed to load compatibility score');
    }
  } catch (error) {
    console.error('Error loading compatibility score:', error);
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
