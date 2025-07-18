import { supabase } from '@/integrations/supabase/client';
import EmailService from './EmailService';

export interface FeedbackData {
  type: 'bug' | 'feature' | 'improvement' | 'general';
  priority: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  description: string;
  userEmail?: string | undefined;
  includeSystemInfo: boolean;
  includeScreenshot: boolean;
  rating?: number | undefined;
}

export interface FeedbackRecord {
  id: string;
  user_id?: string | undefined;
  user_email?: string | undefined;
  type: string;
  priority: string;
  title: string;
  description: string;
  system_info?: any;
  status: 'pending' | 'reviewed' | 'in_progress' | 'resolved' | 'closed';
  admin_notes?: string | undefined;
  created_at: string;
  updated_at: string;
}

class FeedbackService {
  private static instance: FeedbackService;

  private constructor() {}

  public static getInstance(): FeedbackService {
    if (!FeedbackService.instance) {
      FeedbackService.instance = new FeedbackService();
    }
    return FeedbackService.instance;
  }

  /**
   * Geri bildirim gönder
   */
  async submitFeedback(feedbackData: FeedbackData): Promise<{ success: boolean; data?: FeedbackRecord; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      const systemInfo = feedbackData.includeSystemInfo ? this.getSystemInfo() : undefined;
      
      // E-posta servisi ile geri bildirim gönder
      const emailService = EmailService.getInstance();
      
      // Admin'e geri bildirim e-postası gönder
      const emailResult = await emailService.sendFeedbackEmail(feedbackData, systemInfo);
      if (!emailResult.success) {
        console.warn('Admin e-postası gönderilemedi:', emailResult.error);
      }

      // Kullanıcıya onay e-postası gönder (e-posta adresi varsa)
      if (feedbackData.userEmail || user?.email) {
        const confirmationResult = await emailService.sendConfirmationEmail(
          feedbackData.userEmail || user?.email!,
          feedbackData
        );
        if (!confirmationResult.success) {
          console.warn('Onay e-postası gönderilemedi:', confirmationResult.error);
        }
      }

      // Geçici olarak console.log ile simüle ediyoruz
      // Migration çalıştırıldıktan sonra gerçek Supabase çağrısı yapılacak
      console.log('Geri bildirim gönderiliyor:', {
        user_id: user?.id,
        user_email: feedbackData.userEmail || user?.email || 'admin@budgiebreedingtracker.com',
        type: feedbackData.type,
        priority: feedbackData.priority,
        title: feedbackData.title.trim(),
        description: feedbackData.description.trim(),
        system_info: systemInfo,
        status: 'pending',
        email_sent: emailResult.success,
        confirmation_sent: feedbackData.userEmail || user?.email ? true : false
      });

      // Simüle edilmiş başarılı yanıt
      const mockData: FeedbackRecord = {
        id: crypto.randomUUID(),
        user_id: user?.id,
        user_email: feedbackData.userEmail || user?.email || 'admin@budgiebreedingtracker.com',
        type: feedbackData.type,
        priority: feedbackData.priority,
        title: feedbackData.title.trim(),
        description: feedbackData.description.trim(),
        system_info: systemInfo,
        status: 'pending',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      return { success: true, data: mockData };
    } catch (error) {
      console.error('Geri bildirim servisi hatası:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Beklenmeyen hata' 
      };
    }
  }

  /**
   * Kullanıcının geri bildirimlerini getir
   */
  async getUserFeedback(): Promise<{ success: boolean; data?: FeedbackRecord[]; error?: string }> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        return { success: false, error: 'Kullanıcı oturumu bulunamadı' };
      }

      // Geçici olarak boş array döndürüyoruz
      console.log('Kullanıcı geri bildirimleri getiriliyor:', user.id);
      return { success: true, data: [] };
    } catch (error) {
      console.error('Geri bildirim servisi hatası:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Beklenmeyen hata' 
      };
    }
  }

  /**
   * Geri bildirim durumunu güncelle
   */
  async updateFeedbackStatus(
    feedbackId: string, 
    status: FeedbackRecord['status'], 
    adminNotes?: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      // Geçici olarak console.log ile simüle ediyoruz
      console.log('Geri bildirim durumu güncelleniyor:', { feedbackId, status, adminNotes });
      return { success: true };
    } catch (error) {
      console.error('Geri bildirim servisi hatası:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Beklenmeyen hata' 
      };
    }
  }

  /**
   * Sistem bilgilerini topla
   */
  private getSystemInfo() {
    return {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      language: navigator.language,
      screenResolution: `${screen.width}x${screen.height}`,
      windowSize: `${window.innerWidth}x${window.innerHeight}`,
      timestamp: new Date().toISOString(),
      url: window.location.href,
      referrer: document.referrer,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      cookiesEnabled: navigator.cookieEnabled,
      online: navigator.onLine,
      deviceMemory: (navigator as any).deviceMemory,
      hardwareConcurrency: navigator.hardwareConcurrency
    };
  }

  /**
   * Geri bildirim istatistiklerini getir (admin için)
   */
  async getFeedbackStats(): Promise<{ success: boolean; data?: any; error?: string }> {
    try {
      // Geçici olarak mock istatistikler döndürüyoruz
      console.log('Geri bildirim istatistikleri getiriliyor');
      const mockStats = {
        total: 0,
        byType: { bug: 0, feature: 0, improvement: 0, general: 0 },
        byPriority: { low: 0, medium: 0, high: 0, critical: 0 },
        byStatus: { pending: 0, reviewed: 0, in_progress: 0, resolved: 0, closed: 0 },
        recent: 0
      };
      return { success: true, data: mockStats };
    } catch (error) {
      console.error('Geri bildirim istatistikleri hatası:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Beklenmeyen hata' 
      };
    }
  }
}

export default FeedbackService; 