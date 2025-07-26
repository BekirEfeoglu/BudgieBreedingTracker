import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { 
  SubscriptionPlan, 
  UserSubscription, 
  UserProfile, 
  PremiumFeatures,
  SubscriptionLimits,
  TrialInfo 
} from '@/types/subscription';

export const useSubscription = () => {
  const { user } = useAuth();
  const [subscriptionPlans, setSubscriptionPlans] = useState<SubscriptionPlan[]>([]);
  const [userSubscription, setUserSubscription] = useState<UserSubscription | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Abonelik planlarını yükle
  const fetchSubscriptionPlans = useCallback(async () => {
    try {
      const { data, error } = await (supabase as any)
        .from('subscription_plans')
        .select('*')
        .eq('is_active', true)
        .order('price_monthly', { ascending: true });

      if (error) {
        console.error('Abonelik planları yüklenirken hata:', error);
        // Tablo yoksa varsayılan planları kullan
        if (error.code === '42P01') {
          console.log('Subscription plans tablosu bulunamadı, varsayılan planlar kullanılıyor');
          setSubscriptionPlans([]);
          return;
        }
        setError('Abonelik planları yüklenemedi');
        return;
      }

      setSubscriptionPlans((data as any) || []);
    } catch (err) {
      console.error('Abonelik planları yüklenirken hata:', err);
      setError('Abonelik planları yüklenemedi');
    }
  }, []);

  // Kullanıcı aboneliğini yükle
  const fetchUserSubscription = useCallback(async () => {
    if (!user) return;

    try {
      const { data, error } = await (supabase as any)
        .from('user_subscriptions')
        .select('*')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (error) {
        console.error('Kullanıcı aboneliği yüklenirken hata:', error);
        // Tablo yoksa veya kayıt yoksa null olarak ayarla
        if (error.code === '42P01' || error.code === 'PGRST116') {
          console.log('User subscriptions tablosu bulunamadı veya kayıt yok');
          setUserSubscription(null);
          return;
        }
        setError('Abonelik bilgileri yüklenemedi');
        return;
      }

      setUserSubscription(data as any);
    } catch (err) {
      console.error('Kullanıcı aboneliği yüklenirken hata:', err);
      setError('Abonelik bilgileri yüklenemedi');
    }
  }, [user]);

  // Kullanıcı profilini yükle
  const fetchUserProfile = useCallback(async () => {
    if (!user) return;

    try {
      // Profili subscription alanları ile birlikte yükle
      const { data, error } = await (supabase as any)
        .from('profiles')
        .select('id, first_name, last_name, avatar_url, subscription_status, subscription_plan_id, subscription_expires_at, trial_ends_at, updated_at')
        .eq('id', user.id);

      if (error) {
        console.error('Kullanıcı profili yüklenirken hata:', error);
        setError('Profil bilgileri yüklenemedi');
        return;
      }

      // Array'den ilk elemanı al
      const profileData = Array.isArray(data) && data.length > 0 ? data[0] : null;
      
      if (!profileData) {
        console.error('Profil verisi bulunamadı');
        setError('Profil bilgileri bulunamadı');
        return;
      }

      // Profili doğrudan kullan, eksik alanlar için varsayılan değerler
      const profileWithDefaults: UserProfile = {
        id: profileData.id,
        first_name: profileData.first_name,
        last_name: profileData.last_name,
        avatar_url: profileData.avatar_url,
        subscription_status: profileData.subscription_status || 'free',
        subscription_plan_id: profileData.subscription_plan_id || null,
        subscription_expires_at: profileData.subscription_expires_at || null,
        trial_ends_at: profileData.trial_ends_at || null,
        updated_at: profileData.updated_at
      };

      setUserProfile(profileWithDefaults);
    } catch (err) {
      console.error('Kullanıcı profili yüklenirken hata:', err);
      setError('Profil bilgileri yüklenemedi');
    }
  }, [user]);

  // Premium özelliklerini hesapla
  const getPremiumFeatures = useCallback((): PremiumFeatures => {
    if (!userProfile) {
      return {
        unlimited_birds: false,
        unlimited_incubations: false,
        unlimited_eggs: false,
        unlimited_chicks: false,
        cloud_sync: false,
        advanced_stats: false,
        genealogy: false,
        data_export: false,
        unlimited_notifications: false,
        ad_free: false,
        custom_notifications: false,
        auto_backup: false,
      };
    }

    const isPremium = userProfile.subscription_status === 'premium' && 
                     (!userProfile.subscription_expires_at || 
                      new Date(userProfile.subscription_expires_at) > new Date());

    return {
      unlimited_birds: isPremium,
      unlimited_incubations: isPremium,
      unlimited_eggs: isPremium,
      unlimited_chicks: isPremium,
      cloud_sync: isPremium,
      advanced_stats: isPremium,
      genealogy: isPremium,
      data_export: isPremium,
      unlimited_notifications: isPremium,
      ad_free: isPremium,
      custom_notifications: isPremium,
      auto_backup: isPremium,
    };
  }, [userProfile]);

  // Abonelik limitlerini hesapla
  const getSubscriptionLimits = useCallback((): SubscriptionLimits => {
    // Geçici olarak premium sistem devre dışı - tüm kullanıcılara sınırsız izin ver
    // TODO: Premium sistem tamamlandığında bu kontrolü tekrar aktif et
    return {
      birds: -1, // Sınırsız
      incubations: -1,
      eggs: -1,
      chicks: -1,
      notifications: -1,
    };

    // Orijinal kod (premium sistem aktif olduğunda kullanılacak):
    /*
    if (!userProfile) {
      console.log('🔒 useSubscription.getSubscriptionLimits - Profil yok, varsayılan limitler döndürülüyor');
      return {
        birds: 3,
        incubations: 1,
        eggs: 6,
        chicks: 3,
        notifications: 5,
      };
    }

    const isPremium = userProfile.subscription_status === 'premium' && 
                     (!userProfile.subscription_expires_at || 
                      new Date(userProfile.subscription_expires_at) > new Date());

    console.log('🔒 useSubscription.getSubscriptionLimits - Premium durumu:', isPremium);

    if (isPremium) {
      console.log('🔒 useSubscription.getSubscriptionLimits - Premium kullanıcı, sınırsız limitler');
      return {
        birds: -1, // Sınırsız
        incubations: -1,
        eggs: -1,
        chicks: -1,
        notifications: -1,
      };
    }

    console.log('🔒 useSubscription.getSubscriptionLimits - Free kullanıcı, sınırlı limitler');
    return {
      birds: 3,
      incubations: 1,
      eggs: 6,
      chicks: 3,
      notifications: 5,
    };
    */
  }, [userProfile]);

  // Trial bilgilerini hesapla
  const getTrialInfo = useCallback((): TrialInfo => {
    if (!userProfile) {
      return {
        is_trial_available: false,
        trial_days: 0,
        trial_end_date: null,
        days_remaining: 0,
      };
    }

    const trialEndDate = userProfile.trial_ends_at ? new Date(userProfile.trial_ends_at) : null;
    const now = new Date();
    
    const isTrialActive = trialEndDate && trialEndDate > now;
    const daysRemaining = trialEndDate ? Math.ceil((trialEndDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)) : 0;

    return {
      is_trial_available: !userProfile.trial_ends_at || isTrialActive,
      trial_days: 3,
      trial_end_date: userProfile.trial_ends_at,
      days_remaining: Math.max(0, daysRemaining),
    };
  }, [userProfile]);

  // Premium durumunu kontrol et
  const isPremium = useCallback((): boolean => {
    if (!userProfile) return false;
    
    const status = userProfile.subscription_status;
    const expiresAt = userProfile.subscription_expires_at;
    const now = new Date();
    
    const isPremiumStatus = status === 'premium' || status === 'Premium';
    const isNotExpired = !expiresAt || new Date(expiresAt) > now;
    
    return isPremiumStatus && isNotExpired;
  }, [userProfile]);

  // Trial durumunu kontrol et
  const isTrial = useCallback((): boolean => {
    if (!userProfile) return false;
    
    const status = userProfile.subscription_status;
    const trialEndsAt = userProfile.trial_ends_at;
    const now = new Date();
    
    const isTrialStatus = status === 'trial' || status === 'Trial';
    const isTrialActive = trialEndsAt && new Date(trialEndsAt) > now;
    
    return isTrialStatus && isTrialActive;
  }, [userProfile]);

  // Özellik limitini kontrol et
  const checkFeatureLimit = useCallback(async (featureName: string, currentCount: number = 0): Promise<boolean> => {
    if (!user) return false;

    try {
      const { data, error } = await supabase.rpc('check_feature_limit', {
        user_uuid: user.id,
        feature_name: featureName,
        current_count: currentCount
      });

      if (error) {
        console.error('Özellik limiti kontrol edilirken hata:', error);
        // Fonksiyon yoksa varsayılan limitleri kullan
        return currentCount < 10; // Güvenli varsayılan limit
      }

      return data;
    } catch (err) {
      console.error('Özellik limiti kontrol edilirken hata:', err);
      return currentCount < 10; // Güvenli varsayılan limit
    }
  }, [user]);

  // Abonelik durumunu güncelle
  const updateSubscriptionStatus = useCallback(async (
    newStatus: string, 
    planId?: string, 
    expiresAt?: string
  ): Promise<boolean> => {
    if (!user) return false;

    try {
      const { error } = await supabase.rpc('update_subscription_status', {
        user_uuid: user.id,
        new_status: newStatus,
        plan_id: planId,
        expires_at: expiresAt
      });

      if (error) {
        console.error('Abonelik durumu güncellenirken hata:', error);
        // Fonksiyon yoksa manuel güncelleme yap
        if (error.code === '42883') {
          console.log('update_subscription_status fonksiyonu bulunamadı, manuel güncelleme yapılıyor');
          // Manuel güncelleme için profiles tablosunu güncelle
          const updateData: any = {
            subscription_status: newStatus,
            subscription_plan_id: planId,
            updated_at: new Date().toISOString()
          };
          
          // Trial durumunda trial_ends_at alanını da güncelle
          if (newStatus === 'trial' && expiresAt) {
            updateData.trial_ends_at = expiresAt;
          } else if (newStatus === 'premium' && expiresAt) {
            updateData.subscription_expires_at = expiresAt;
          }
          
          const { error: updateError } = await supabase
            .from('profiles')
            .update(updateData)
            .eq('id', user.id);
          
          if (updateError) {
            console.error('Manuel güncelleme hatası:', updateError);
            return false;
          }
          
          await fetchUserProfile();
          return true;
        }
        return false;
      }

      // Profili yeniden yükle
      await fetchUserProfile();
      return true;
    } catch (err) {
      console.error('Abonelik durumu güncellenirken hata:', err);
      return false;
    }
  }, [user, fetchUserProfile]);

  // Verileri yeniden yükle
  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    await Promise.all([
      fetchSubscriptionPlans(),
      fetchUserSubscription(),
      fetchUserProfile()
    ]);
    
    setLoading(false);
  }, [fetchSubscriptionPlans, fetchUserSubscription, fetchUserProfile]);

  // Trial süresi kontrolü - süre bittiğinde otomatik olarak free durumuna geç
  useEffect(() => {
    if (userProfile && userProfile.subscription_status === 'trial' && userProfile.trial_ends_at) {
      const trialEndDate = new Date(userProfile.trial_ends_at);
      const now = new Date();
      
      if (trialEndDate <= now) {
        console.log('🔄 Trial süresi bitti, otomatik olarak free durumuna geçiliyor');
        updateSubscriptionStatus('free');
      }
    }
  }, [userProfile, updateSubscriptionStatus]);

  // Periyodik trial süresi kontrolü (her 5 dakikada bir)
  useEffect(() => {
    if (!userProfile || userProfile.subscription_status !== 'trial' || !userProfile.trial_ends_at) {
      return;
    }

    const checkTrialExpiry = () => {
      const trialEndDate = new Date(userProfile.trial_ends_at);
      const now = new Date();
      
      if (trialEndDate <= now) {
        console.log('🔄 Periyodik kontrol: Trial süresi bitti, otomatik olarak free durumuna geçiliyor');
        updateSubscriptionStatus('free');
      }
    };

    // İlk kontrol
    checkTrialExpiry();
    
    // Her 5 dakikada bir kontrol et
    const interval = setInterval(checkTrialExpiry, 5 * 60 * 1000);
    
    return () => clearInterval(interval);
  }, [userProfile, updateSubscriptionStatus]);

  // İlk yükleme
  useEffect(() => {
    if (user) {
      refresh();
    } else {
      setLoading(false);
    }
  }, [user, refresh]);

  return {
    // State
    subscriptionPlans,
    userSubscription,
    userProfile,
    loading,
    error,
    
    // Computed values
    isPremium: isPremium(),
    isTrial: isTrial(),
    premiumFeatures: getPremiumFeatures(),
    subscriptionLimits: getSubscriptionLimits(),
    trialInfo: getTrialInfo(),
    
    // Actions
    checkFeatureLimit,
    updateSubscriptionStatus,
    refresh,
  };
}; 