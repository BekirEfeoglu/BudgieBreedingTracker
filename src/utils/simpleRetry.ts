// Basit ve güvenilir retry mekanizması
// Supabase'in kendi retry mekanizması yerine kullanılır

export interface RetryOptions {
  maxAttempts: number;
  baseDelay: number;
  maxDelay: number;
  backoffMultiplier: number;
  timeoutMs: number;
}

const defaultOptions: RetryOptions = {
  maxAttempts: 3,
  baseDelay: 1000,
  maxDelay: 10000,
  backoffMultiplier: 2,
  timeoutMs: 30000,
};

export class SimpleRetry {
  private options: RetryOptions;

  constructor(options: Partial<RetryOptions> = {}) {
    this.options = { ...defaultOptions, ...options };
  }

  async execute<T>(
    operation: () => Promise<T>,
    operationName: string = 'Operation'
  ): Promise<T> {
    let lastError: Error;
    let attempt = 1;

    while (attempt <= this.options.maxAttempts) {
      try {
        console.log(`🔄 ${operationName} - Deneme ${attempt}/${this.options.maxAttempts}`);
        
        // Timeout ile operation'ı sarmala
        const result = await this.withTimeout(operation(), this.options.timeoutMs);
        
        console.log(`✅ ${operationName} - Başarılı (Deneme ${attempt})`);
        return result;
        
      } catch (error) {
        lastError = error as Error;
        console.warn(`❌ ${operationName} - Deneme ${attempt} başarısız:`, error);
        
        if (attempt === this.options.maxAttempts) {
          console.error(`💥 ${operationName} - Tüm denemeler başarısız`);
          throw lastError;
        }
        
        // Exponential backoff ile bekle
        const delay = Math.min(
          this.options.baseDelay * Math.pow(this.options.backoffMultiplier, attempt - 1),
          this.options.maxDelay
        );
        
        console.log(`⏳ ${operationName} - ${delay}ms bekleniyor...`);
        await this.sleep(delay);
        attempt++;
      }
    }
    
    throw lastError!;
  }

  private async withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => {
        reject(new Error(`İşlem zaman aşımına uğradı (${timeoutMs}ms)`));
      }, timeoutMs);
    });

    return Promise.race([promise, timeoutPromise]);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Hazır retry instance'ları
export const authRetry = new SimpleRetry({
  maxAttempts: 8,
  baseDelay: 3000,
  maxDelay: 30000,
  timeoutMs: 120000,
});

export const dataRetry = new SimpleRetry({
  maxAttempts: 3,
  baseDelay: 1000,
  maxDelay: 8000,
  timeoutMs: 45000,
});

// Utility fonksiyonlar
export const retryAuth = <T>(operation: () => Promise<T>, name?: string) => {
  return authRetry.execute(operation, name);
};

export const retryData = <T>(operation: () => Promise<T>, name?: string) => {
  return dataRetry.execute(operation, name);
}; 