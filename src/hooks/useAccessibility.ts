import { useEffect, useCallback } from 'react';

interface AccessibilityOptions {
  announcePageChanges?: boolean;
  manageFocus?: boolean;
  enableKeyboardNavigation?: boolean;
}

export const useAccessibility = (options: AccessibilityOptions = {}) => {
  const {
    announcePageChanges = true,
    manageFocus = true,
    enableKeyboardNavigation = true
  } = options;

  // Screen reader announcements
  const _announce = useCallback((message: string, priority: 'polite' | 'assertive' = 'polite') => {
    const announcer = document.createElement('div');
    announcer.setAttribute('aria-live', priority);
    announcer.setAttribute('aria-atomic', 'true');
    announcer.className = 'sr-only';
    announcer.textContent = message;
    
    document.body.appendChild(announcer);
    
    setTimeout(() => {
      document.body.removeChild(announcer);
    }, 1000);
  }, []);

  // Focus management
  const _focusElement = useCallback((selector: string) => {
    const element = document.querySelector(selector) as HTMLElement;
    if (element) {
      element.focus();
      element.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, []);

  // Skip to main content
  const addSkipLink = useCallback(() => {
    if (document.querySelector('#skip-link')) return;
    
    const skipLink = document.createElement('a');
    skipLink.id = 'skip-link';
    skipLink.href = '#main-content';
    skipLink.textContent = 'Ana içeriğe atla';
    skipLink.className = 'sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-primary text-primary-foreground px-4 py-2 rounded z-50';
    
    document.body.insertBefore(skipLink, document.body.firstChild);
  }, []);

  // Keyboard navigation
  useEffect(() => {
    if (!enableKeyboardNavigation) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      // ESC key to close modals/dropdowns
      if (event.key === 'Escape') {
        const activeModal = document.querySelector('[role="dialog"]:not([hidden])');
        if (activeModal) {
          const closeButton = activeModal.querySelector('[aria-label*="close"], [aria-label*="kapat"]') as HTMLElement;
          closeButton?.click();
          return;
        }
      }

      // Tab trapping for modals
      if (event.key === 'Tab') {
        const activeModal = document.querySelector('[role="dialog"]:not([hidden])');
        if (activeModal) {
          const focusableElements = activeModal.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
          );
          
          if (focusableElements.length > 0) {
            const firstElement = focusableElements[0] as HTMLElement;
            const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;
            
            if (event.shiftKey && document.activeElement === firstElement) {
              event.preventDefault();
              lastElement.focus();
            } else if (!event.shiftKey && document.activeElement === lastElement) {
              event.preventDefault();
              firstElement.focus();
            }
          }
        }
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [enableKeyboardNavigation]);

  // Initialize accessibility features
  useEffect(() => {
    addSkipLink();
    
    // Add landmarks if missing
    if (!document.querySelector('main')) {
      const mainContent = document.querySelector('#root > div');
      if (mainContent) {
        mainContent.setAttribute('role', 'main');
        mainContent.id = 'main-content';
      }
    }
  }, [addSkipLink]);

  return {
    _announce,
    _focusElement
  };
};