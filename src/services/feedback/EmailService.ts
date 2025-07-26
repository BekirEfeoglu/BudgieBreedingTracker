import { supabase } from '@/integrations/supabase/client';

export interface EmailData {
  to: string;
  subject: string;
  body: string;
  from?: string;
}

export class EmailService {
  private static instance: EmailService;
  private adminEmail = 'admin@budgiebreedingtracker.com';
  private sendGridApiKey = import.meta.env.VITE_SENDGRID_API_KEY || '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';
  private fromEmail = 'noreply@sendgrid.net';

  static getInstance(): EmailService {
    if (!EmailService.instance) {
      EmailService.instance = new EmailService();
    }
    return EmailService.instance;
  }

  async sendFeedbackEmail(feedbackData: {
    type: string;
    title: string;
    description: string;
    userEmail?: string;
    userName?: string;
  }): Promise<{ success: boolean; error?: any }> {
    try {
      console.log('📧 Geri bildirim e-postası gönderiliyor:', feedbackData);
      
      // Şimdilik sadece mock e-posta kullan
      console.log('🔄 Mock e-posta gönderiliyor...');
      return await this.mockSendEmail({
        to: this.adminEmail,
        subject: `[Geri Bildirim] ${feedbackData.type.toUpperCase()}: ${feedbackData.title}`,
        body: this.createFeedbackEmailBody(feedbackData),
        from: this.fromEmail
      });
    } catch (error) {
      console.error('E-posta gönderme hatası:', error);
      // Hata durumunda mock e-posta gönder
      console.log('🔄 Hata durumunda mock e-posta gönderiliyor...');
      return await this.mockSendEmail({
        to: this.adminEmail,
        subject: `[Geri Bildirim] ${feedbackData.type.toUpperCase()}: ${feedbackData.title}`,
        body: this.createFeedbackEmailBody(feedbackData),
        from: this.fromEmail
      });
    }
  }

  private async sendWithSupabaseFunction(feedbackData: {
    type: string;
    title: string;
    description: string;
    userEmail?: string;
    userName?: string;
  }): Promise<{ success: boolean; error?: any }> {
    try {
      console.log('🔄 Supabase Edge Function deneniyor...');
      
      // Supabase client kullanarak Edge Function'a istek yap
      const { data, error } = await supabase.functions.invoke('send-email', {
        body: { feedbackData },
      });

      if (error) {
        console.error('❌ Supabase Edge Function hatası:', error);
        throw new Error(`Edge Function Error: ${error.message}`);
      }

      if (data) {
        console.log('✅ E-posta başarıyla gönderildi (Supabase Edge Function)');
        return { success: true };
      } else {
        throw new Error('Edge Function returned no data');
      }
    } catch (error) {
      console.error('❌ Supabase Edge Function API hatası:', error);
      throw error;
    }
  }

  private async sendWithSendGridDirectly(feedbackData: {
    type: string;
    title: string;
    description: string;
    userEmail?: string;
    userName?: string;
  }): Promise<{ success: boolean; error?: any }> {
    try {
      const sendGridApiKey = import.meta.env.VITE_SENDGRID_API_KEY || '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';
      
      console.log('📧 SendGrid API ile e-posta gönderimi deneniyor...');
      console.log('🔑 SendGrid API Key Length:', sendGridApiKey?.length || 0);
      
      if (!sendGridApiKey) {
        throw new Error('SendGrid API key not found');
      }

      const emailData = {
        personalizations: [
          {
            to: [{ email: this.adminEmail }],
            subject: `[Geri Bildirim] ${feedbackData.type.toUpperCase()}: ${feedbackData.title}`,
          },
        ],
        from: { email: this.fromEmail },
        content: [
          {
            type: 'text/plain',
            value: this.createFeedbackEmailBody(feedbackData),
          },
        ],
      };

      const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${sendGridApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(emailData),
      });

      if (response.ok) {
        console.log('✅ E-posta başarıyla gönderildi (SendGrid)');
        return { success: true };
      } else {
        const errorData = await response.text();
        console.error('❌ SendGrid e-posta gönderme hatası:', response.status, errorData);
        throw new Error(`SendGrid Error: ${response.status}`);
      }
    } catch (error) {
      console.error('❌ SendGrid API hatası:', error);
      throw error;
    }
  }

  private createFeedbackEmailBody(feedbackData: {
    type: string;
    title: string;
    description: string;
    userEmail?: string;
    userName?: string;
  }): string {
    const typeLabels = {
      bug: 'Hata Bildirimi',
      feature: 'Özellik Önerisi',
      improvement: 'İyileştirme Önerisi',
      general: 'Genel Geri Bildirim'
    };

    return `
Yeni bir geri bildirim alındı:

📋 TÜR: ${typeLabels[feedbackData.type as keyof typeof typeLabels] || feedbackData.type}
📝 BAŞLIK: ${feedbackData.title}
📄 AÇIKLAMA: ${feedbackData.description}
👤 KULLANICI: ${feedbackData.userName || 'Anonim'}
📧 E-POSTA: ${feedbackData.userEmail || 'Belirtilmemiş'}
🕒 TARİH: ${new Date().toLocaleString('tr-TR')}

---
Bu e-posta BudgieBreedingTracker uygulamasından otomatik olarak gönderilmiştir.
Yanıtlamak için: admin@budgiebreedingtracker.com
    `.trim();
  }

  private async mockSendEmail(emailData: EmailData): Promise<{ success: boolean; error?: any }> {
    // Simüle edilmiş gecikme
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    console.log('✅ E-posta başarıyla gönderildi (Mock)');
    console.log('📧 Alıcı:', emailData.to);
    console.log('📧 Konu:', emailData.subject);
    console.log('📧 İçerik:', emailData.body);
    
    return { success: true };
  }
}

export default EmailService; 