import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["input", "form"]
  
  connect() {
    console.log("Search controller connected")
  }
  
  // プルダウン変更時のフォーム送信
  submitForm(event) {
    console.log("Select changed, submitting form")
    this.formTarget.requestSubmit()
  }
  
  // エンターキーでの検索
  submitOnEnter(event) {
    if (event.key === "Enter") {
      this.formTarget.requestSubmit()
    }
  }
  
  // クリアボタンの処理
  clear(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    // URLのパラメータをクリアしてページをリロード
    window.location.href = window.location.pathname
  }
}
