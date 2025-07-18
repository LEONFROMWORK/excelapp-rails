import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]
  static classes = ["open"]
  
  connect() {
    this.isOpen = false
    
    // Close dropdown when clicking outside
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.boundHandleOutsideClick)
    
    // Close dropdown on escape key
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundHandleEscape)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleOutsideClick)
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  toggle(event) {
    event.stopPropagation()
    
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (this.isOpen) return
    
    this.isOpen = true
    this.showMenu()
    this.element.setAttribute('data-state', 'open')
    
    // Focus first menu item for accessibility
    this.focusFirstMenuItem()
    
    // Dispatch custom event
    this.dispatch('opened')
  }

  close() {
    if (!this.isOpen) return
    
    this.isOpen = false
    this.hideMenu()
    this.element.setAttribute('data-state', 'closed')
    
    // Return focus to trigger button
    const trigger = this.element.querySelector('[data-action*="dropdown#toggle"]')
    if (trigger) {
      trigger.focus()
    }
    
    // Dispatch custom event
    this.dispatch('closed')
  }

  showMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("hidden")
      
      // Add animation classes
      this.menuTarget.classList.add(
        "transform", "transition-all", "duration-200", "ease-out"
      )
      
      // Trigger animation
      requestAnimationFrame(() => {
        this.menuTarget.classList.add(
          "opacity-100", "scale-100", "translate-y-0"
        )
        this.menuTarget.classList.remove(
          "opacity-0", "scale-95", "translate-y-1"
        )
      })
    }
  }

  hideMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add(
        "opacity-0", "scale-95", "translate-y-1"
      )
      this.menuTarget.classList.remove(
        "opacity-100", "scale-100", "translate-y-0"
      )
      
      // Hide after animation
      setTimeout(() => {
        this.menuTarget.classList.add("hidden")
      }, 200)
    }
  }

  handleOutsideClick(event) {
    if (this.isOpen && !this.element.contains(event.target)) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.isOpen) {
      this.close()
    }
  }

  focusFirstMenuItem() {
    if (!this.hasMenuTarget) return
    
    const firstMenuItem = this.menuTarget.querySelector(
      'a, button, [tabindex]:not([tabindex="-1"])'
    )
    
    if (firstMenuItem) {
      firstMenuItem.focus()
    }
  }

  // Handle keyboard navigation in menu
  handleMenuKeydown(event) {
    if (!this.isOpen) return
    
    const menuItems = Array.from(
      this.menuTarget.querySelectorAll(
        'a, button, [tabindex]:not([tabindex="-1"])'
      )
    )
    
    if (menuItems.length === 0) return
    
    const currentIndex = menuItems.indexOf(document.activeElement)
    
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        const nextIndex = (currentIndex + 1) % menuItems.length
        menuItems[nextIndex].focus()
        break
        
      case "ArrowUp":
        event.preventDefault()
        const prevIndex = currentIndex <= 0 ? menuItems.length - 1 : currentIndex - 1
        menuItems[prevIndex].focus()
        break
        
      case "Home":
        event.preventDefault()
        menuItems[0].focus()
        break
        
      case "End":
        event.preventDefault()
        menuItems[menuItems.length - 1].focus()
        break
        
      case "Tab":
        // Allow default tab behavior but close menu
        this.close()
        break
    }
  }

  // Action to handle menu item selection
  selectItem(event) {
    // Close menu after selection (unless it's a submenu)
    if (!event.target.closest('[data-submenu]')) {
      this.close()
    }
  }
}