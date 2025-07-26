import { supabase } from '@/integrations/supabase/client';
import EmailService from './EmailService';

export interface FeedbackData {
  id?: string;
  userId: string;
  type: 'bug' | 'feature' | 'general' | 'improvement';
  title: string;
  description: string;
  rating?: number;
  status: 'pending' | 'reviewed' | 'resolved' | 'closed';
  createdAt?: string;
  updatedAt?: string;
}

export class FeedbackService {
  private static instance: FeedbackService;

  static getInstance(): FeedbackService {
    if (!FeedbackService.instance) {
      FeedbackService.instance = new FeedbackService();
    }
    return FeedbackService.instance;
  }

  async submitFeedback(feedback: Omit<FeedbackData, 'id' | 'status' | 'createdAt' | 'updatedAt'>): Promise<{ success: boolean; id?: string; error?: any }> {
    try {
      // Mock implementation - gerçek veritabanı tablosu yok
      const mockId = crypto.randomUUID();
      const now = new Date().toISOString();
      
      const feedbackData: FeedbackData = {
        ...feedback,
        id: mockId,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      };

      console.log('Mock feedback gönderildi:', feedbackData);
      
      // E-posta gönderimi
      const emailService = EmailService.getInstance();
      
      // Kullanıcı bilgilerini al
      let userEmail = 'Anonim';
      let userName = 'Kullanıcı';
      
      try {
        // Supabase'den kullanıcı bilgilerini al
        const { data: userData, error: userError } = await supabase.auth.getUser();
        if (userData?.user?.email) {
          userEmail = userData.user.email;
        }
        
        // Profil tablosundan kullanıcı adını al
        const { data: profileData, error: profileError } = await supabase
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', feedback.userId)
          .single();
          
        if (profileData && !profileError) {
          const firstName = profileData.first_name || '';
          const lastName = profileData.last_name || '';
          userName = `${firstName} ${lastName}`.trim() || 'Kullanıcı';
        } else if (userData?.user?.user_metadata?.full_name) {
          userName = userData.user.user_metadata.full_name;
        }
      } catch (error) {
        console.warn('Kullanıcı bilgileri alınamadı:', error);
      }
      
      const emailResult = await emailService.sendFeedbackEmail({
        type: feedback.type,
        title: feedback.title,
        description: feedback.description,
        userEmail: userEmail,
        userName: userName
      });

      if (!emailResult.success) {
        console.warn('E-posta gönderilemedi:', emailResult.error);
      }
      
      return { success: true, id: mockId };
    } catch (error) {
      console.error('Feedback gönderme hatası:', error);
      return { success: false, error };
    }
  }

  async getFeedbackList(userId: string): Promise<{ success: boolean; data?: FeedbackData[]; error?: any }> {
    try {
      // Mock feedback listesi
      const mockFeedbacks: FeedbackData[] = [
        {
          id: '1',
          userId,
          type: 'bug',
          title: 'Uygulama açılmıyor',
          description: 'Uygulama başlatılırken hata veriyor',
          rating: 1,
          status: 'resolved',
          createdAt: '2025-07-20T10:00:00Z',
          updatedAt: '2025-07-21T10:00:00Z',
        },
        {
          id: '2',
          userId,
          type: 'feature',
          title: 'Yeni özellik önerisi',
          description: 'Kuluçka takvimi eklenebilir mi?',
          rating: 5,
          status: 'reviewed',
          createdAt: '2025-07-19T10:00:00Z',
          updatedAt: '2025-07-20T10:00:00Z',
        },
      ];

      return { success: true, data: mockFeedbacks };
    } catch (error) {
      console.error('Feedback listesi getirme hatası:', error);
      return { success: false, error };
    }
  }

  async updateFeedbackStatus(feedbackId: string, status: FeedbackData['status']): Promise<{ success: boolean; error?: any }> {
    try {
      // Mock implementation
      console.log('Mock feedback durumu güncellendi:', feedbackId, status);
      return { success: true };
    } catch (error) {
      console.error('Feedback durumu güncelleme hatası:', error);
      return { success: false, error };
    }
  }

  async deleteFeedback(feedbackId: string): Promise<{ success: boolean; error?: any }> {
    try {
      // Mock implementation
      console.log('Mock feedback silindi:', feedbackId);
      return { success: true };
    } catch (error) {
      console.error('Feedback silme hatası:', error);
      return { success: false, error };
    }
  }
}

export default FeedbackService; 