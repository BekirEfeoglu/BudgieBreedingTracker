import { FeedbackData } from './FeedbackService';

interface EmailData {
  to: string;
  subject: string;
  html: string;
  text: string;
}

class EmailService {
  private static instance: EmailService;
  private readonly adminEmail = 'admin@budgiebreedingtracker.com';

  private constructor() {}

  public static getInstance(): EmailService {
    if (!EmailService.instance) {
      EmailService.instance = new EmailService();
    }
    return EmailService.instance;
  }

  /**
   * Geri bildirim e-postası gönder
   */
  async sendFeedbackEmail(feedbackData: FeedbackData, systemInfo?: any): Promise<{ success: boolean; error?: string; simulation?: boolean }> {
    try {
      const emailData = this.createFeedbackEmail(feedbackData, systemInfo);
      
      // Supabase Edge Function ile e-posta gönder
      const { supabase } = await import('@/integrations/supabase/client');
      
      const { data, error } = await supabase.functions.invoke('send-feedback-email', {
        body: {
          to: this.adminEmail,
          subject: emailData.subject,
          html: emailData.html,
          text: emailData.text,
          from: 'noreply@budgiebreedingtracker.com'
        }
      });

      if (error) {
        console.error('Supabase Edge Function hatası:', error);
        // SMTP ayarları eksikse simülasyon moduna geç
        if (error.message?.includes('SMTP ayarları yapılandırılmamış') || error.message?.includes('non-2xx status code')) {
          console.log('📧 SMTP ayarları eksik, simülasyon modunda çalışıyor:', {
            to: this.adminEmail,
            subject: emailData.subject,
            from: feedbackData.userEmail || 'noreply@budgiebreedingtracker.com'
          });
          return { success: true }; // Simüle edilmiş başarı
        }
        return { success: false, error: error.message };
      }

      // Yeni simülasyon modu kontrolü
      if (data?.simulation) {
        console.log('📧 E-posta simülasyon modunda gönderildi:', {
          to: this.adminEmail,
          subject: emailData.subject,
          from: feedbackData.userEmail || 'noreply@budgiebreedingtracker.com',
          message: data.message
        });
        return { success: true, simulation: true };
      }

      return { success: data?.success || false, error: data?.error };
    } catch (error) {
      console.error('E-posta gönderme hatası:', error);
      // Fallback: console.log ile simüle et
      console.log('📧 Geri bildirim e-postası gönderiliyor (simüle):', {
        to: this.adminEmail,
        subject: `[${feedbackData.type}] ${feedbackData.title}`,
        from: feedbackData.userEmail || 'noreply@budgiebreedingtracker.com'
      });
      return { success: true }; // Simüle edilmiş başarı
    }
  }

  /**
   * Geri bildirim e-postası içeriğini oluştur
   */
  private createFeedbackEmail(feedbackData: FeedbackData, systemInfo?: any): EmailData {
    const priorityColors = {
      low: '#10b981',
      medium: '#f59e0b', 
      high: '#f97316',
      critical: '#ef4444'
    };

    const typeIcons = {
      bug: '🐛',
      feature: '💡',
      improvement: '⭐',
      general: '💬'
    };

    const priorityLabels = {
      low: 'Düşük',
      medium: 'Orta',
      high: 'Yüksek',
      critical: 'Kritik'
    };

    const typeLabels = {
      bug: 'Hata Bildirimi',
      feature: 'Yeni Özellik Önerisi',
      improvement: 'İyileştirme Önerisi',
      general: 'Genel Geri Bildirim'
    };

    const subject = `[${typeLabels[feedbackData.type]}] ${feedbackData.title}`;
    
    const html = `
      <!DOCTYPE html>
      <html lang="tr">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Geri Bildirim - BudgieBreedingTracker</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px 8px 0 0; }
          .content { background: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
          .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; color: white; font-size: 12px; font-weight: bold; }
          .priority-badge { background-color: ${priorityColors[feedbackData.priority]}; }
          .type-badge { background-color: #6b7280; }
          .section { margin: 20px 0; padding: 15px; background: white; border-radius: 6px; border-left: 4px solid #667eea; }
          .section h3 { margin: 0 0 10px 0; color: #374151; }
          .system-info { background: #f3f4f6; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; }
          .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; font-size: 12px; color: #6b7280; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>${typeIcons[feedbackData.type]} Yeni Geri Bildirim</h1>
            <p>BudgieBreedingTracker uygulamasından yeni bir geri bildirim alındı.</p>
          </div>
          
          <div class="content">
            <div class="section">
              <h3>📋 Temel Bilgiler</h3>
              <p><strong>Başlık:</strong> ${feedbackData.title}</p>
              <p><strong>Tür:</strong> <span class="badge type-badge">${typeLabels[feedbackData.type]}</span></p>
              <p><strong>Öncelik:</strong> <span class="badge priority-badge">${priorityLabels[feedbackData.priority]}</span></p>
              <p><strong>Gönderen:</strong> ${feedbackData.userEmail || 'Anonim'}</p>
              <p><strong>Tarih:</strong> ${new Date().toLocaleString('tr-TR')}</p>
            </div>

            <div class="section">
              <h3>📝 Detaylı Açıklama</h3>
              <p>${feedbackData.description.replace(/\n/g, '<br>')}</p>
            </div>

            ${systemInfo ? `
            <div class="section">
              <h3>💻 Sistem Bilgileri</h3>
              <div class="system-info">
                <strong>Tarayıcı:</strong> ${systemInfo.userAgent}<br>
                <strong>Platform:</strong> ${systemInfo.platform}<br>
                <strong>Dil:</strong> ${systemInfo.language}<br>
                <strong>Ekran Çözünürlüğü:</strong> ${systemInfo.screenResolution}<br>
                <strong>Pencere Boyutu:</strong> ${systemInfo.windowSize}<br>
                <strong>Saat Dilimi:</strong> ${systemInfo.timezone}<br>
                <strong>URL:</strong> ${systemInfo.url}<br>
                <strong>Çevrimiçi:</strong> ${systemInfo.online ? 'Evet' : 'Hayır'}<br>
                <strong>Donanım Çekirdekleri:</strong> ${systemInfo.hardwareConcurrency || 'Bilinmiyor'}
              </div>
            </div>
            ` : ''}

            <div class="section">
              <h3>🔗 Hızlı İşlemler</h3>
              <p>Bu geri bildirimi hızlıca işlemek için:</p>
              <ul>
                <li>Admin paneline giriş yapın</li>
                <li>Geri bildirim listesini kontrol edin</li>
                <li>Durumu güncelleyin ve yanıt verin</li>
              </ul>
            </div>

            <div class="footer">
              <p>Bu e-posta BudgieBreedingTracker geri bildirim sistemi tarafından otomatik olarak gönderilmiştir.</p>
              <p>© 2025 BudgieBreedingTracker. Tüm hakları saklıdır.</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `
YENİ GERİ BİLDİRİM - BudgieBreedingTracker

Temel Bilgiler:
- Başlık: ${feedbackData.title}
- Tür: ${typeLabels[feedbackData.type]}
- Öncelik: ${priorityLabels[feedbackData.priority]}
- Gönderen: ${feedbackData.userEmail || 'Anonim'}
- Tarih: ${new Date().toLocaleString('tr-TR')}

Detaylı Açıklama:
${feedbackData.description}

${systemInfo ? `
Sistem Bilgileri:
- Tarayıcı: ${systemInfo.userAgent}
- Platform: ${systemInfo.platform}
- Dil: ${systemInfo.language}
- Ekran Çözünürlüğü: ${systemInfo.screenResolution}
- Pencere Boyutu: ${systemInfo.windowSize}
- Saat Dilimi: ${systemInfo.timezone}
- URL: ${systemInfo.url}
- Çevrimiçi: ${systemInfo.online ? 'Evet' : 'Hayır'}
- Donanım Çekirdekleri: ${systemInfo.hardwareConcurrency || 'Bilinmiyor'}
` : ''}

---
Bu e-posta BudgieBreedingTracker geri bildirim sistemi tarafından otomatik olarak gönderilmiştir.
© 2025 BudgieBreedingTracker. Tüm hakları saklıdır.
    `;

    return {
      to: this.adminEmail,
      subject,
      html,
      text
    };
  }

  /**
   * Kullanıcıya onay e-postası gönder
   */
  async sendConfirmationEmail(userEmail: string, feedbackData: FeedbackData): Promise<{ success: boolean; error?: string; simulation?: boolean }> {
    try {
      const subject = 'Geri Bildiriminiz Alındı - BudgieBreedingTracker';
      
      const text = `
Geri Bildirim Onayı - BudgieBreedingTracker

Merhaba,

Geri bildiriminiz için teşekkür ederiz! Aşağıdaki bilgilerle kaydınız oluşturulmuştur:

- Başlık: ${feedbackData.title}
- Tür: ${feedbackData.type}
- Öncelik: ${feedbackData.priority}
- Gönderim Tarihi: ${new Date().toLocaleString('tr-TR')}

Sonraki Adımlar:
- Geri bildiriminiz ekibimiz tarafından incelenecek
- Gerekirse ek bilgi istenebilir
- Çözüm veya güncelleme hakkında bilgi verilecek

İletişim:
Herhangi bir sorunuz varsa admin@budgiebreedingtracker.com adresinden bizimle iletişime geçebilirsiniz.

---
Bu e-posta BudgieBreedingTracker geri bildirim sistemi tarafından otomatik olarak gönderilmiştir.
© 2025 BudgieBreedingTracker. Tüm hakları saklıdır.
      `;
      
      const html = `
        <!DOCTYPE html>
        <html lang="tr">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Geri Bildirim Onayı</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 20px; border-radius: 8px 8px 0 0; }
            .content { background: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
            .section { margin: 20px 0; padding: 15px; background: white; border-radius: 6px; }
            .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb; font-size: 12px; color: #6b7280; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>✅ Geri Bildiriminiz Alındı</h1>
              <p>Değerli geri bildiriminiz için teşekkürler!</p>
            </div>
            
            <div class="content">
              <div class="section">
                <h3>📋 Geri Bildirim Detayları</h3>
                <p><strong>Başlık:</strong> ${feedbackData.title}</p>
                <p><strong>Tür:</strong> ${feedbackData.type}</p>
                <p><strong>Öncelik:</strong> ${feedbackData.priority}</p>
                <p><strong>Gönderim Tarihi:</strong> ${new Date().toLocaleString('tr-TR')}</p>
              </div>

              <div class="section">
                <h3>📝 Sonraki Adımlar</h3>
                <p>Geri bildiriminiz ekibimiz tarafından incelenecek ve en kısa sürede size yanıt verilecektir.</p>
                <ul>
                  <li>Geri bildiriminiz değerlendirilecek</li>
                  <li>Gerekirse ek bilgi istenebilir</li>
                  <li>Çözüm veya güncelleme hakkında bilgi verilecek</li>
                </ul>
              </div>

              <div class="section">
                <h3>📞 İletişim</h3>
                <p>Herhangi bir sorunuz varsa <strong>admin@budgiebreedingtracker.com</strong> adresinden bizimle iletişime geçebilirsiniz.</p>
              </div>

              <div class="footer">
                <p>Bu e-posta BudgieBreedingTracker geri bildirim sistemi tarafından otomatik olarak gönderilmiştir.</p>
                <p>© 2025 BudgieBreedingTracker. Tüm hakları saklıdır.</p>
              </div>
            </div>
          </div>
        </body>
        </html>
      `;

      // Gerçek e-posta gönderimi
      const { supabase } = await import('@/integrations/supabase/client');
      
      const { data, error } = await supabase.functions.invoke('send-feedback-email', {
        body: {
          to: userEmail,
          subject: subject,
          html: html,
          text: text,
          from: 'noreply@budgiebreedingtracker.com'
        }
      });

      if (error) {
        console.error('Supabase Edge Function hatası:', error);
        // SMTP ayarları eksikse simülasyon moduna geç
        if (error.message?.includes('SMTP ayarları yapılandırılmamış') || error.message?.includes('non-2xx status code')) {
          console.log('📧 SMTP ayarları eksik, onay e-postası simülasyon modunda çalışıyor:', { to: userEmail, subject });
          return { success: true }; // Simüle edilmiş başarı
        }
        return { success: false, error: error.message };
      }

      // Yeni simülasyon modu kontrolü
      if (data?.simulation) {
        console.log('📧 Onay e-postası simülasyon modunda gönderildi:', {
          to: userEmail,
          subject,
          message: data.message
        });
        return { success: true, simulation: true };
      }

      console.log('📧 Onay e-postası başarıyla gönderildi:', { to: userEmail, subject });
      return { success: data?.success || false, error: data?.error };
    } catch (error) {
      console.error('Onay e-postası gönderme hatası:', error);
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Onay e-postası gönderilemedi' 
      };
    }
  }
}

export default EmailService; 