import { useState, useEffect, useCallback, useRef } from 'react';
import { Bird, Chick } from '@/types';

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttl: number; // Time to live in milliseconds
}

interface PerformanceMetrics {
  loadTime: number;
  renderTime: number;
  memoryUsage: number;
  cacheHitRate: number;
}

interface UseGenealogyPerformanceOptions {
  enableLazyLoading?: boolean;
  enableCaching?: boolean;
  enableOfflineMode?: boolean;
  enableSync?: boolean;
  cacheTTL?: number; // milliseconds
  batchSize?: number;
}

export const useGenealogyPerformance = (options: UseGenealogyPerformanceOptions = {}) => {
  const {
    enableLazyLoading = true,
    enableCaching = true,
    enableOfflineMode = true,
    enableSync = true,
    cacheTTL = 5 * 60 * 1000, // 5 minutes
    batchSize = 20
  } = options;

  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [isLoading, setIsLoading] = useState(false);
  const [performanceMetrics, setPerformanceMetrics] = useState<PerformanceMetrics>({
    loadTime: 0,
    renderTime: 0,
    memoryUsage: 0,
    cacheHitRate: 0
  });

  const cache = useRef<Map<string, CacheEntry<any>>>(new Map());
  const pendingSync = useRef<Set<string>>(new Set());
  const loadStartTime = useRef<number>(0);
  const renderStartTime = useRef<number>(0);

  // Online/offline durumu takibi
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Önbellek yönetimi
  const getCachedData = useCallback(<T>(key: string): T | null => {
    if (!enableCaching) return null;

    const entry = cache.current.get(key);
    if (!entry) return null;

    const isExpired = Date.now() - entry.timestamp > entry.ttl;
    if (isExpired) {
      cache.current.delete(key);
      return null;
    }

    return entry.data;
  }, [enableCaching]);

  const setCachedData = useCallback(<T>(key: string, data: T, ttl?: number): void => {
    if (!enableCaching) return;

    cache.current.set(key, {
      data,
      timestamp: Date.now(),
      ttl: ttl || cacheTTL
    });
  }, [enableCaching, cacheTTL]);

  const clearCache = useCallback((pattern?: string): void => {
    if (pattern) {
      for (const key of cache.current.keys()) {
        if (key.includes(pattern)) {
          cache.current.delete(key);
        }
      }
    } else {
      cache.current.clear();
    }
  }, []);

  // Lazy loading
  const loadDataInBatches = useCallback(async <T>(
    dataLoader: (offset: number, limit: number) => Promise<T[]>,
    totalCount: number
  ): Promise<T[]> => {
    if (!enableLazyLoading) {
      return dataLoader(0, totalCount);
    }

    const results: T[] = [];
    let offset = 0;

    while (offset < totalCount) {
      const batch = await dataLoader(offset, batchSize);
      results.push(...batch);
      offset += batchSize;

      // Batch arası kısa bekleme (UI'ın responsive kalması için)
      if (offset < totalCount) {
        await new Promise(resolve => setTimeout(resolve, 10));
      }
    }

    return results;
  }, [enableLazyLoading, batchSize]);

  // Offline veri yönetimi
  const saveOfflineData = useCallback((key: string, data: any): void => {
    if (!enableOfflineMode) return;

    try {
      localStorage.setItem(`genealogy_offline_${key}`, JSON.stringify({
        data,
        timestamp: Date.now()
      }));
    } catch (error) {
      console.error('Offline veri kaydetme hatası:', error);
    }
  }, [enableOfflineMode]);

  const getOfflineData = useCallback(<T>(key: string): T | null => {
    if (!enableOfflineMode) return null;

    try {
      const stored = localStorage.getItem(`genealogy_offline_${key}`);
      if (!stored) return null;

      const parsed = JSON.parse(stored);
      const isExpired = Date.now() - parsed.timestamp > 24 * 60 * 60 * 1000; // 24 saat

      if (isExpired) {
        localStorage.removeItem(`genealogy_offline_${key}`);
        return null;
      }

      return parsed.data;
    } catch (error) {
      console.error('Offline veri okuma hatası:', error);
      return null;
    }
  }, [enableOfflineMode]);

  // Senkronizasyon
  const syncData = useCallback(async (key: string, data: any): Promise<void> => {
    if (!enableSync || !isOnline) {
      pendingSync.current.add(key);
      saveOfflineData(key, data);
      return;
    }

    try {
      // Gerçek uygulamada burada API çağrısı yapılacak
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Veri senkronize edildi:', key);
      
      pendingSync.current.delete(key);
    } catch (error) {
      console.error('Senkronizasyon hatası:', error);
      pendingSync.current.add(key);
      saveOfflineData(key, data);
    }
  }, [enableSync, isOnline, saveOfflineData]);

  const syncPendingData = useCallback(async (): Promise<void> => {
    if (!enableSync || !isOnline || pendingSync.current.size === 0) return;

    setIsLoading(true);
    try {
      const pendingKeys = Array.from(pendingSync.current);
      
      for (const key of pendingKeys) {
        const offlineData = getOfflineData(key);
        if (offlineData) {
          await syncData(key, offlineData);
        }
      }
    } catch (error) {
      console.error('Bekleyen veri senkronizasyon hatası:', error);
    } finally {
      setIsLoading(false);
    }
  }, [enableSync, isOnline, syncData, getOfflineData]);

  // Performans ölçümü
  const startLoadTimer = useCallback((): void => {
    loadStartTime.current = performance.now();
  }, []);

  const endLoadTimer = useCallback((): void => {
    const loadTime = performance.now() - loadStartTime.current;
    setPerformanceMetrics(prev => ({ ...prev, loadTime }));
  }, []);

  const startRenderTimer = useCallback((): void => {
    renderStartTime.current = performance.now();
  }, []);

  const endRenderTimer = useCallback((): void => {
    const renderTime = performance.now() - renderStartTime.current;
    setPerformanceMetrics(prev => ({ ...prev, renderTime }));
  }, []);

  // Bellek kullanımı takibi
  const updateMemoryUsage = useCallback((): void => {
    if ('memory' in performance) {
      const memory = (performance as any).memory;
      const memoryUsage = (memory.usedJSHeapSize / memory.totalJSHeapSize) * 100;
      setPerformanceMetrics(prev => ({ ...prev, memoryUsage }));
    }
  }, []);

  // Önbellek hit rate hesaplama
  const updateCacheHitRate = useCallback((hits: number, misses: number): void => {
    const total = hits + misses;
    const hitRate = total > 0 ? (hits / total) * 100 : 0;
    setPerformanceMetrics(prev => ({ ...prev, cacheHitRate: hitRate }));
  }, []);

  // Performans optimizasyonu için debounce
  const debounce = useCallback(<T extends (...args: any[]) => any>(
    func: T,
    delay: number
  ): ((...args: Parameters<T>) => void) => {
    let timeoutId: NodeJS.Timeout;
    return (...args: Parameters<T>) => {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => func(...args), delay);
    };
  }, []);

  // Virtual scrolling için görünür öğe hesaplama
  const getVisibleItems = useCallback(
    (items: any[], containerHeight: number, itemHeight: number, scrollTop: number) => {
      const startIndex = Math.floor(scrollTop / itemHeight);
      const endIndex = Math.min(
        startIndex + Math.ceil(containerHeight / itemHeight) + 1,
        items.length
      );

      return {
        items: items.slice(startIndex, endIndex),
        startIndex,
        endIndex,
        totalHeight: items.length * itemHeight
      };
    },
    []
  );

  // Performans temizleme
  const cleanup = useCallback((): void => {
    clearCache();
    pendingSync.current.clear();
    setPerformanceMetrics({
      loadTime: 0,
      renderTime: 0,
      memoryUsage: 0,
      cacheHitRate: 0
    });
  }, [clearCache]);

  // Otomatik temizleme (her 30 dakikada bir)
  useEffect(() => {
    const interval = setInterval(() => {
      // Süresi dolmuş önbellek girişlerini temizle
      const now = Date.now();
      for (const [key, entry] of cache.current.entries()) {
        if (now - entry.timestamp > entry.ttl) {
          cache.current.delete(key);
        }
      }

      // Bellek kullanımını güncelle
      updateMemoryUsage();
    }, 30 * 60 * 1000); // 30 dakika

    return () => clearInterval(interval);
  }, [updateMemoryUsage]);

  return {
    // Durum
    isOnline,
    isLoading,
    performanceMetrics,
    
    // Önbellek işlemleri
    getCachedData,
    setCachedData,
    clearCache,
    
    // Lazy loading
    loadDataInBatches,
    
    // Offline işlemler
    saveOfflineData,
    getOfflineData,
    
    // Senkronizasyon
    syncData,
    syncPendingData,
    pendingSyncCount: pendingSync.current.size,
    
    // Performans ölçümü
    startLoadTimer,
    endLoadTimer,
    startRenderTimer,
    endRenderTimer,
    updateMemoryUsage,
    updateCacheHitRate,
    
    // Yardımcı fonksiyonlar
    debounce,
    getVisibleItems,
    cleanup
  };
};

// Özel hook'lar
export const useFamilyTreeCache = () => {
  const [familyCache, setFamilyCache] = useState<Map<string, any>>(new Map());

  const cacheFamilyData = useCallback((birdId: string, familyData: any) => {
    setFamilyCache(prev => new Map(prev.set(birdId, {
      data: familyData,
      timestamp: Date.now()
    })));
  }, []);

  const getCachedFamilyData = useCallback((birdId: string) => {
    return familyCache.get(birdId);
  }, [familyCache]);

  const clearFamilyCache = useCallback(() => {
    setFamilyCache(new Map());
  }, []);

  return {
    cacheFamilyData,
    getCachedFamilyData,
    clearFamilyCache,
    cacheSize: familyCache.size
  };
};

 