// Manuel Auth İşlemleri - Supabase'in kendi retry mekanizmasını bypass eder
// Bu dosya, 504 hatalarını çözmek için alternatif bir yaklaşım sağlar

import { supabase } from '@/integrations/supabase/client';

const SUPABASE_URL = "https://jxbfdgyusoehqybxdnii.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4YmZkZ3l1c29laHF5YnhkbmlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMjY5NTksImV4cCI6MjA2NjgwMjk1OX0.aBMXWV0";

interface ManualAuthOptions {
  maxAttempts: number;
  baseDelay: number;
  maxDelay: number;
  timeoutMs: number;
}

const defaultOptions: ManualAuthOptions = {
  maxAttempts: 10,
  baseDelay: 5000,
  maxDelay: 60000,
  timeoutMs: 180000, // 3 dakika
};

export class ManualAuth {
  private options: ManualAuthOptions;

  constructor(options: Partial<ManualAuthOptions> = {}) {
    this.options = { ...defaultOptions, ...options };
  }

  private async sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private async withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => {
        reject(new Error(`İşlem zaman aşımına uğradı (${timeoutMs}ms)`));
      }, timeoutMs);
    });

    return Promise.race([promise, timeoutPromise]);
  }

  private calculateDelay(attempt: number): number {
    // Exponential backoff with jitter
    const baseDelay = this.options.baseDelay * Math.pow(2, attempt - 1);
    const jitter = Math.random() * 0.1 * baseDelay; // %10 jitter
    return Math.min(baseDelay + jitter, this.options.maxDelay);
  }

  async signUp(email: string, password: string, userData?: any): Promise<any> {
    console.log('🚀 Manuel Kayıt İşlemi Başlatılıyor...');
    
    let lastError: Error;
    
    for (let attempt = 1; attempt <= this.options.maxAttempts; attempt++) {
      try {
        console.log(`🔄 Manuel Kayıt - Deneme ${attempt}/${this.options.maxAttempts}`);
        
        // Her denemede yeni bir fetch request oluştur
        const response = await this.withTimeout(
          fetch(`${SUPABASE_URL}/auth/v1/signup`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': SUPABASE_PUBLISHABLE_KEY,
              'Authorization': `Bearer ${SUPABASE_PUBLISHABLE_KEY}`,
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
            body: JSON.stringify({
              email: email.toLowerCase().trim(),
              password: password,
              options: {
                emailRedirectTo: 'https://www.budgiebreedingtracker.com/',
                data: userData || {}
              }
            })
          }),
          this.options.timeoutMs
        );

        if (response.ok) {
          const data = await response.json();
          console.log(`✅ Manuel Kayıt Başarılı (Deneme ${attempt})`);
          return { data, error: null };
        } else {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(`HTTP ${response.status}: ${JSON.stringify(errorData)}`);
        }
        
      } catch (error) {
        lastError = error as Error;
        console.warn(`❌ Manuel Kayıt - Deneme ${attempt} başarısız:`, error);
        
        if (attempt === this.options.maxAttempts) {
          console.error(`💥 Manuel Kayıt - Tüm denemeler başarısız`);
          throw lastError;
        }
        
        // Exponential backoff ile bekle
        const delay = this.calculateDelay(attempt);
        console.log(`⏳ Manuel Kayıt - ${delay}ms bekleniyor...`);
        await this.sleep(delay);
      }
    }
    
    throw lastError!;
  }

  async signIn(email: string, password: string): Promise<any> {
    console.log('🚀 Manuel Giriş İşlemi Başlatılıyor...');
    
    let lastError: Error;
    
    for (let attempt = 1; attempt <= this.options.maxAttempts; attempt++) {
      try {
        console.log(`🔄 Manuel Giriş - Deneme ${attempt}/${this.options.maxAttempts}`);
        
        const response = await this.withTimeout(
          fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': SUPABASE_PUBLISHABLE_KEY,
              'Authorization': `Bearer ${SUPABASE_PUBLISHABLE_KEY}`,
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
            body: JSON.stringify({
              email: email.toLowerCase().trim(),
              password: password
            })
          }),
          this.options.timeoutMs
        );

        if (response.ok) {
          const data = await response.json();
          console.log(`✅ Manuel Giriş Başarılı (Deneme ${attempt})`);
          return { data, error: null };
        } else {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(`HTTP ${response.status}: ${JSON.stringify(errorData)}`);
        }
        
      } catch (error) {
        lastError = error as Error;
        console.warn(`❌ Manuel Giriş - Deneme ${attempt} başarısız:`, error);
        
        if (attempt === this.options.maxAttempts) {
          console.error(`💥 Manuel Giriş - Tüm denemeler başarısız`);
          throw lastError;
        }
        
        const delay = this.calculateDelay(attempt);
        console.log(`⏳ Manuel Giriş - ${delay}ms bekleniyor...`);
        await this.sleep(delay);
      }
    }
    
    throw lastError!;
  }

  async resetPassword(email: string): Promise<any> {
    console.log('🚀 Manuel Şifre Sıfırlama Başlatılıyor...');
    
    let lastError: Error;
    
    for (let attempt = 1; attempt <= this.options.maxAttempts; attempt++) {
      try {
        console.log(`🔄 Manuel Şifre Sıfırlama - Deneme ${attempt}/${this.options.maxAttempts}`);
        
        const response = await this.withTimeout(
          fetch(`${SUPABASE_URL}/auth/v1/recover`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': SUPABASE_PUBLISHABLE_KEY,
              'Authorization': `Bearer ${SUPABASE_PUBLISHABLE_KEY}`,
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
            body: JSON.stringify({
              email: email.toLowerCase().trim(),
              redirectTo: 'https://www.budgiebreedingtracker.com/'
            })
          }),
          this.options.timeoutMs
        );

        if (response.ok) {
          const data = await response.json();
          console.log(`✅ Manuel Şifre Sıfırlama Başarılı (Deneme ${attempt})`);
          return { data, error: null };
        } else {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(`HTTP ${response.status}: ${JSON.stringify(errorData)}`);
        }
        
      } catch (error) {
        lastError = error as Error;
        console.warn(`❌ Manuel Şifre Sıfırlama - Deneme ${attempt} başarısız:`, error);
        
        if (attempt === this.options.maxAttempts) {
          console.error(`💥 Manuel Şifre Sıfırlama - Tüm denemeler başarısız`);
          throw lastError;
        }
        
        const delay = this.calculateDelay(attempt);
        console.log(`⏳ Manuel Şifre Sıfırlama - ${delay}ms bekleniyor...`);
        await this.sleep(delay);
      }
    }
    
    throw lastError!;
  }
}

// Hazır instance
export const manualAuth = new ManualAuth();

// Utility fonksiyonlar
export const manualSignUp = (email: string, password: string, userData?: any) => {
  return manualAuth.signUp(email, password, userData);
};

export const manualSignIn = (email: string, password: string) => {
  return manualAuth.signIn(email, password);
};

export const manualResetPassword = (email: string) => {
  return manualAuth.resetPassword(email);
}; 