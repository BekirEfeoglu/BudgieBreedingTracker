// Mobile-specific Supabase client configuration
// React Native için optimize edildi

import 'react-native-url-polyfill/auto'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { createClient, processLock } from '@supabase/supabase-js'
import type { Database } from './types';

// Mobile için Supabase konfigürasyonu
const SUPABASE_URL = "https://etkvuonkmmzihsjwbcrl.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzandiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE";

// Debug için API key'i kontrol et
console.log('🔑 Mobile Supabase URL:', SUPABASE_URL);
console.log('🔑 Mobile Supabase Key Length:', SUPABASE_ANON_KEY?.length || 0);
console.log('🔑 Mobile Supabase Key Starts With:', SUPABASE_ANON_KEY?.substring(0, 20) || 'undefined');
console.log('✅ Mobile uygulaması için optimize edildi');

export const supabaseMobile = createClient<Database>(
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  {
    auth: {
      storage: AsyncStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
      lock: processLock,
    },
    global: {
      headers: {
        'X-Client-Info': 'budgie-breeding-tracker-mobile',
        'Cache-Control': 'no-cache',
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'application/json',
      },
    },
    realtime: {
      params: {
        eventsPerSecond: 10,
      },
    },
  }
);

// Mobile için timeout wrapper
export const withTimeoutMobile = async <T>(
  promise: Promise<T>,
  timeoutMs: number = 30000
): Promise<T> => {
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => {
      reject(new Error(`Mobile işlem zaman aşımına uğradı (${timeoutMs}ms)`));
    }, timeoutMs);
  });

  return Promise.race([promise, timeoutPromise]);
};

// Mobile için retry wrapper
export const withRetryMobile = async <T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  delayMs: number = 1000
): Promise<T> => {
  let lastError: Error;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error as Error;
      console.warn(`Mobile deneme ${attempt}/${maxRetries} başarısız:`, error);
      
      if (attempt === maxRetries) {
        throw lastError;
      }
      
      // Exponential backoff
      const delay = delayMs * Math.pow(2, attempt - 1);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw lastError!;
}; 