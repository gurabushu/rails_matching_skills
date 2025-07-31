import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "content"]
  
  connect() {
    // 初期化時に最初のタブをアクティブにする
    this.showTab('matched')
  }
  
  switch(event) {
    const tabName = event.currentTarget.dataset.tab
    this.showTab(tabName)
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
