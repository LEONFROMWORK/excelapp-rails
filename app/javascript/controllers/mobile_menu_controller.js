import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-menu"
export default class extends Controller {
  static targets = ["menu", "backdrop"]

  connect() {
    this.isOpen = false
    
    // Close menu on escape key
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundHandleEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  open() {
    this.isOpen = true
    this.showElements()
    this.lockBodyScroll()
    
    // Focus trap for accessibility
    this.trapFocus()
  }

  close() {
    this.isOpen = false
    this.hideElements()
    this.unlockBodyScroll()
    
    // Return focus to trigger button
    const menuButton = document.querySelector('[data-action*="mobile-menu#open"]')
    if (menuButton) {
      menuButton.focus()
    }
  }

  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
    }
  }

  showElements() {
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden")
      // Trigger animation
      requestAnimationFrame(() => {
        this.backdropTarget.classList.add("opacity-100")
      })
    }
    
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("hidden")
      // Trigger slide-in animation
      requestAnimationFrame(() => {
        this.menuTarget.classList.add("translate-x-0")
        this.menuTarget.classList.remove("translate-x-full")
      })
    }
  }

  hideElements() {
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-100")
      setTimeout(() => {
        this.backdropTarget.classList.add("hidden")
      }, 300)
    }
    
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("translate-x-full")
      this.menuTarget.classList.remove("translate-x-0")
      setTimeout(() => {
        this.menuTarget.classList.add("hidden")
      }, 300)
    }
  }

  lockBodyScroll() {
    document.body.style.overflow = "hidden"
  }

  unlockBodyScroll() {
    document.body.style.overflow = ""
  }

  trapFocus() {
    if (!this.hasMenuTarget) return

    const focusableElements = this.menuTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    
    if (focusableElements.length === 0) return

    const firstElement = focusableElements[0]
    const lastElement = focusableElements[focusableElements.length - 1]

    // Focus first element
    firstElement.focus()

    // Handle tab navigation
    this.boundHandleTab = (event) => {
      if (event.key !== "Tab") return

      if (event.shiftKey) {
        // Shift + Tab
        if (document.activeElement === firstElement) {
          event.preventDefault()
          lastElement.focus()
        }
      } else {
        // Tab
        if (document.activeElement === lastElement) {
          event.preventDefault()
          firstElement.focus()
        }
      }
    }

    document.addEventListener("keydown", this.boundHandleTab)
  }
}