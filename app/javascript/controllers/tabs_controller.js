import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "content"]
  static values = { defaultTab: String }
  
  connect() {
    // デフォルトタブまたは最初のタブをアクティブにする
    const defaultTab = this.hasDefaultTabValue ? this.defaultTabValue : 'matched'
    
    // URLのハッシュからタブを決定
    const hash = window.location.hash.replace('#', '')
    const targetTab = hash || defaultTab
    
    this.showTab(targetTab)
  }
  
  switch(event) {
    event.preventDefault()
    const tabName = event.currentTarget.dataset.tab
    this.showTab(tabName)
    
    // URLハッシュを更新（任意）
    if (history.replaceState) {
      history.replaceState(null, null, `#${tabName}`)
    }
  }
  
  showTab(tabName) {
    // すべてのタブボタンを非アクティブにする
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.classList.remove('active')
    })
    
    // すべてのタブコンテンツを隠す
    document.querySelectorAll('.tab-content').forEach(content => {
      content.classList.remove('active')
    })
    
    // 選択されたタブボタンをアクティブにする
    const activeTabBtn = document.querySelector(`[data-tab="${tabName}"]`)
    if (activeTabBtn) {
      activeTabBtn.classList.add('active')
    }
    
    // 選択されたタブコンテンツを表示する
    const activeTabContent = document.getElementById(`${tabName}-tab`)
    if (activeTabContent) {
      activeTabContent.classList.add('active')
    }
  }
}
