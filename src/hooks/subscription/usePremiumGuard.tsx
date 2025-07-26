import { useCallback } from 'react';
import { useSubscription } from './useSubscription';
import { useToast } from '@/hooks/use-toast';

export interface PremiumGuardOptions {
  feature: string;
  showUpgradePrompt?: boolean;
  redirectToUpgrade?: boolean;
}

export const usePremiumGuard = () => {
  const { isPremium, premiumFeatures, subscriptionLimits, error: subscriptionError } = useSubscription();
  const { toast } = useToast();

  // Premium özellik kontrolü
  const checkPremiumFeature = useCallback((feature: keyof typeof premiumFeatures): boolean => {
    // Hata durumunda varsayılan olarak izin ver
    if (subscriptionError) {
      return true;
    }
    
    return premiumFeatures[feature];
  }, [premiumFeatures, subscriptionError]);

  // Özellik limit kontrolü
  const checkFeatureLimit = useCallback((feature: keyof typeof subscriptionLimits, currentCount: number): boolean => {
    // Hata durumunda varsayılan olarak izin ver
    if (subscriptionError) {
      return true;
    }
    
    const limit = subscriptionLimits[feature];
    return limit === -1 || currentCount < limit;
  }, [subscriptionLimits, subscriptionError]);

  // Premium guard fonksiyonu
  const requirePremium = useCallback((options: PremiumGuardOptions & { showToast?: boolean } = {}): boolean => {
    const { feature, showUpgradePrompt = true, showToast = true } = options;

    // Hata durumunda varsayılan olarak izin ver
    if (subscriptionError) {
      return true;
    }

    if (isPremium) {
      return true;
    }

    if (showUpgradePrompt && showToast) {
      toast({
        title: "Premium Özellik Gerekli",
        description: `${feature} özelliğini kullanmak için Premium aboneliğe geçmeniz gerekiyor.`,
        action: (
          <a 
            href="/premium" 
            className="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2"
          >
            Premium'a Geç
          </a>
        ),
        variant: "default",
      });
    }

    return false;
  }, [isPremium, toast, subscriptionError]);

  // Limit kontrolü
  const requireFeatureLimit = useCallback((
    feature: keyof typeof subscriptionLimits, 
    currentCount: number,
    options: Omit<PremiumGuardOptions, 'feature'> & { feature?: string; showToast?: boolean } = {}
  ): boolean => {
    const { showUpgradePrompt = true, showToast = true } = options;
    const featureName = options.feature || feature;

    // Hata durumunda varsayılan olarak izin ver
    if (subscriptionError) {
      return true;
    }

    if (checkFeatureLimit(feature, currentCount)) {
      return true;
    }

    if (showUpgradePrompt && showToast) {
      const limit = subscriptionLimits[feature];
      toast({
        title: "Limit Aşıldı",
        description: `${featureName} limitiniz doldu (${currentCount}/${limit}). Sınırsız kullanım için Premium'a geçin.`,
        action: (
          <a 
            href="/premium" 
            className="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2"
          >
            Premium'a Geç
          </a>
        ),
        variant: "default",
      });
    }

    return false;
  }, [checkFeatureLimit, subscriptionLimits, toast, subscriptionError]);

  // Premium özellik wrapper'ı
  const withPremium = useCallback(<T extends any[], R>(
    feature: keyof typeof premiumFeatures,
    fn: (...args: T) => R,
    fallback?: (...args: T) => R
  ) => {
    return (...args: T): R | undefined => {
      if (checkPremiumFeature(feature)) {
        return fn(...args);
      }
      
      if (fallback) {
        return fallback(...args);
      }
      
      requirePremium({ feature: feature as string });
      return undefined;
    };
  }, [checkPremiumFeature, requirePremium]);

  // Limit wrapper'ı
  const withLimit = useCallback(<T extends any[], R>(
    feature: keyof typeof subscriptionLimits,
    currentCount: number,
    fn: (...args: T) => R,
    fallback?: (...args: T) => R
  ) => {
    return (...args: T): R | undefined => {
      if (checkFeatureLimit(feature, currentCount)) {
        return fn(...args);
      }
      
      if (fallback) {
        return fallback(...args);
      }
      
      requireFeatureLimit(feature, currentCount);
      return undefined;
    };
  }, [checkFeatureLimit, requireFeatureLimit]);

  return {
    // State
    isPremium,
    premiumFeatures,
    subscriptionLimits,
    subscriptionError,
    
    // Check functions
    checkPremiumFeature,
    checkFeatureLimit,
    
    // Guard functions
    requirePremium,
    requireFeatureLimit,
    
    // Wrapper functions
    withPremium,
    withLimit,
  };
}; 