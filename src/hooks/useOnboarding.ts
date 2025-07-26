
import { useState, useEffect } from 'react';

export const useOnboarding = () => {
  const [shouldShowOnboarding, setShouldShowOnboarding] = useState(false);
  const [isOnboardingOpen, setIsOnboardingOpen] = useState(false);

  useEffect(() => {
    // Check if onboarding has been completed or skipped
    const completed = localStorage.getItem('onboarding_completed');
    const skipped = localStorage.getItem('onboarding_skipped');
    
    // Show onboarding if not completed and not skipped
    if (!completed && !skipped) {
      setShouldShowOnboarding(true);
      // Small delay to let the app load first
      setTimeout(() => {
        setIsOnboardingOpen(true);
      }, 500); // Reduced delay for better UX
    }
  }, []);

  const openOnboarding = () => {
    setIsOnboardingOpen(true);
  };

  const closeOnboarding = () => {
    setIsOnboardingOpen(false);
  };

  const completeOnboarding = () => {
    localStorage.setItem('onboarding_completed', 'true');
    setIsOnboardingOpen(false);
    setShouldShowOnboarding(false);
  };

  const resetOnboarding = () => {
    localStorage.removeItem('onboarding_completed');
    localStorage.removeItem('onboarding_skipped');
    setShouldShowOnboarding(true);
    setIsOnboardingOpen(true);
  };

  return {
    shouldShowOnboarding,
    isOnboardingOpen,
    openOnboarding,
    closeOnboarding,
    completeOnboarding,
    resetOnboarding
  };
};
