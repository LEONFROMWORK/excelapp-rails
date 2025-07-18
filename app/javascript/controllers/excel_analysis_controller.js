import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Connects to data-controller="excel-analysis"
export default class extends Controller {
  static targets = ["status", "progress", "progressBar", "message", "analyzeButton", "cancelButton", "results"]
  static values = { 
    fileId: Number,
    userId: Number,
    currentStatus: String
  }

  connect() {
    console.log("Excel Analysis controller connected")
    
    if (!this.fileIdValue) {
      console.error("No file ID provided")
      return
    }

    this.setupWebSocket()
    this.updateUI()
  }

  disconnect() {
    console.log("Excel Analysis controller disconnected")
    this.teardownWebSocket()
  }

  setupWebSocket() {
    this.consumer = createConsumer()
    
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: "ExcelAnalysisChannel",
        file_id: this.fileIdValue
      },
      {
        connected: () => {
          console.log("Connected to Excel Analysis channel")
          this.setConnectionStatus(true)
        },

        disconnected: () => {
          console.log("Disconnected from Excel Analysis channel")
          this.setConnectionStatus(false)
        },

        received: (data) => {
          console.log("Received data:", data)
          this.handleWebSocketMessage(data)
        }
      }
    )
  }

  teardownWebSocket() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
    
    if (this.consumer) {
      this.consumer.disconnect()
      this.consumer = null
    }
  }

  handleWebSocketMessage(data) {
    switch (data.type) {
      case "status":
        this.updateStatus(data)
        break
      case "progress_update":
        this.updateProgress(data.message, data.percentage)
        break
      case "queued":
        this.updateMessage("Analysis queued: " + data.message, "info")
        this.setAnalyzing(true)
        break
      case "analysis_complete":
        this.handleAnalysisComplete(data)
        break
      case "error":
        this.updateMessage("Error: " + data.message, "error")
        this.setAnalyzing(false)
        break
      default:
        console.log("Unknown message type:", data.type)
    }
  }

  updateStatus(data) {
    this.currentStatusValue = data.status
    
    if (data.analysis) {
      this.displayAnalysisResults(data.analysis)
    }
    
    if (data.user_tokens !== undefined) {
      this.updateTokenDisplay(data.user_tokens)
    }
    
    this.updateUI()
  }

  updateProgress(message, percentage) {
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = message
      this.messageTarget.className = "text-sm text-blue-600"
    }
    
    if (this.hasProgressBarTarget && percentage !== undefined) {
      this.progressBarTarget.style.width = `${percentage}%`
      this.progressBarTarget.setAttribute("aria-valuenow", percentage)
    }
    
    if (this.hasProgressTarget) {
      this.progressTarget.textContent = `${percentage}%`
    }
  }

  updateMessage(message, type = "info") {
    if (!this.hasMessageTarget) return
    
    this.messageTarget.textContent = message
    
    const classes = {
      info: "text-sm text-blue-600",
      error: "text-sm text-red-600",
      success: "text-sm text-green-600",
      warning: "text-sm text-yellow-600"
    }
    
    this.messageTarget.className = classes[type] || classes.info
  }

  handleAnalysisComplete(data) {
    this.updateProgress("Analysis complete!", 100)
    this.updateMessage("Analysis completed successfully", "success")
    this.setAnalyzing(false)
    
    if (data.analysis) {
      this.displayAnalysisResults(data.analysis)
    }
    
    // Reload the page to show updated results
    setTimeout(() => {
      window.location.reload()
    }, 2000)
  }

  displayAnalysisResults(analysis) {
    if (!this.hasResultsTarget) return
    
    this.resultsTarget.innerHTML = `
      <div class="bg-white border border-gray-200 rounded-lg p-6 mt-4">
        <h3 class="text-lg font-semibold mb-4">Analysis Results</h3>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div class="text-center p-4 bg-red-50 rounded-lg">
            <div class="text-2xl font-bold text-red-600">${analysis.error_count || 0}</div>
            <div class="text-sm text-gray-600">Errors Found</div>
          </div>
          <div class="text-center p-4 bg-yellow-50 rounded-lg">
            <div class="text-2xl font-bold text-yellow-600">${analysis.warning_count || 0}</div>
            <div class="text-sm text-gray-600">Warnings</div>
          </div>
          <div class="text-center p-4 bg-green-50 rounded-lg">
            <div class="text-2xl font-bold text-green-600">${analysis.confidence_score || 0}%</div>
            <div class="text-sm text-gray-600">Confidence</div>
          </div>
        </div>
        
        ${analysis.ai_analysis ? `
          <div class="mb-4">
            <h4 class="font-medium mb-2">AI Analysis:</h4>
            <div class="bg-gray-50 p-4 rounded-lg text-sm">
              ${this.formatAnalysisText(analysis.ai_analysis)}
            </div>
          </div>
        ` : ''}
        
        <div class="text-xs text-gray-500">
          Analysis completed using AI Tier ${analysis.ai_tier_used || 1} • 
          Provider: ${analysis.provider || 'Unknown'} • 
          Tokens used: ${analysis.tokens_used || 0}
        </div>
      </div>
    `
    
    this.resultsTarget.classList.remove("hidden")
  }

  formatAnalysisText(text) {
    // Basic formatting - convert newlines to <br> and handle simple markdown
    return text
      .replace(/\n/g, '<br>')
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
  }

  updateTokenDisplay(tokens) {
    const tokenElements = document.querySelectorAll('[data-user-tokens]')
    tokenElements.forEach(element => {
      element.textContent = tokens
    })
  }

  updateUI() {
    const status = this.currentStatusValue
    
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = status
      this.statusTarget.className = this.getStatusClass(status)
    }
    
    const isProcessing = status === 'processing'
    const canAnalyze = status === 'uploaded' || status === 'analyzed'
    
    this.setAnalyzing(isProcessing)
    
    if (this.hasAnalyzeButtonTarget) {
      this.analyzeButtonTarget.disabled = !canAnalyze || isProcessing
      this.analyzeButtonTarget.textContent = isProcessing ? 'Analyzing...' : 'Start Analysis'
    }
    
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.style.display = isProcessing ? 'block' : 'none'
    }
  }

  getStatusClass(status) {
    const classes = {
      uploaded: "px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full",
      processing: "px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full",
      analyzed: "px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full",
      failed: "px-2 py-1 text-xs font-medium bg-red-100 text-red-800 rounded-full"
    }
    
    return classes[status] || "px-2 py-1 text-xs font-medium bg-gray-100 text-gray-800 rounded-full"
  }

  setAnalyzing(isAnalyzing) {
    const progressContainer = this.element.querySelector('[data-progress-container]')
    if (progressContainer) {
      progressContainer.style.display = isAnalyzing ? 'block' : 'none'
    }
  }

  setConnectionStatus(connected) {
    const indicator = this.element.querySelector('[data-connection-status]')
    if (indicator) {
      indicator.className = connected 
        ? "w-2 h-2 bg-green-400 rounded-full" 
        : "w-2 h-2 bg-red-400 rounded-full"
    }
  }

  // Action methods
  requestAnalysis() {
    if (!this.subscription) {
      this.updateMessage("Not connected to analysis service", "error")
      return
    }
    
    this.subscription.perform("request_analysis", {
      file_id: this.fileIdValue
    })
    
    this.updateMessage("Requesting analysis...", "info")
  }

  cancelAnalysis() {
    // Implementation would depend on backend support for cancellation
    this.updateMessage("Cancellation requested...", "warning")
  }

  refreshStatus() {
    if (!this.subscription) {
      this.updateMessage("Not connected to analysis service", "error")
      return
    }
    
    this.subscription.perform("get_analysis_status", {
      file_id: this.fileIdValue
    })
  }
}