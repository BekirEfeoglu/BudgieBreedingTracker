import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EmailRequest {
  to: string;
  subject: string;
  html: string;
  text: string;
  from?: string;
}

serve(async (req) => {
  // CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { to, subject, html, text, from = 'noreply@budgiebreedingtracker.com' }: EmailRequest = await req.json()

    console.log('📧 E-posta gönderme isteği alındı:', { to, subject, from })

    // SMTP ayarlarını kontrol et
    const smtpHost = Deno.env.get('SMTP_HOST')
    const smtpPort = Deno.env.get('SMTP_PORT')
    const smtpUsername = Deno.env.get('SMTP_USERNAME')
    const smtpPassword = Deno.env.get('SMTP_PASSWORD')

    // SMTP ayarları eksikse simülasyon modunda çalış
    if (!smtpHost || !smtpPort || !smtpUsername || !smtpPassword) {
      console.log('📧 SMTP ayarları eksik, simülasyon modunda çalışıyor:', { 
        to, 
        subject, 
        from,
        smtpHost: smtpHost ? 'SET' : 'MISSING',
        smtpPort: smtpPort ? 'SET' : 'MISSING',
        smtpUsername: smtpUsername ? 'SET' : 'MISSING',
        smtpPassword: smtpPassword ? 'SET' : 'MISSING'
      })
      
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'E-posta simülasyon modunda gönderildi (SMTP ayarları eksik)',
        simulation: true,
        emailData: { to, subject, from }
      }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      })
    }

    console.log('✅ SMTP ayarları mevcut, e-posta gönderiliyor...')
    
    // IONOS için özel SMTP gönderimi
    try {
      console.log('🔗 IONOS SMTP bağlantısı kuruluyor...', {
        hostname: smtpHost,
        port: parseInt(smtpPort),
        username: smtpUsername,
        password: smtpPassword ? '***' : 'MISSING'
      });

      // IONOS SMTP için özel bağlantı
      const response = await fetch(`https://${smtpHost}:${smtpPort}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${btoa(`${smtpUsername}:${smtpPassword}`)}`
        },
        body: JSON.stringify({
          from: from,
          to: to,
          subject: subject,
          html: html,
          text: text
        })
      });

      if (response.ok) {
        console.log('✅ E-posta başarıyla gönderildi');
        return new Response(JSON.stringify({
          success: true,
          message: 'E-posta başarıyla gönderildi',
          simulation: false
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        });
      } else {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

    } catch (smtpError) {
      console.error('❌ SMTP hatası:', smtpError);
      
      // IONOS için alternatif yöntem: Resend API kullan
      console.log('📧 IONOS SMTP hatası, alternatif yöntem deneniyor...');
      
      try {
        // Resend API ile gönder (ücretsiz alternatif)
        const resendResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY') || 're_123456789'}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            from: from,
            to: to,
            subject: subject,
            html: html,
            text: text
          })
        });

        if (resendResponse.ok) {
          console.log('✅ E-posta Resend API ile başarıyla gönderildi');
          return new Response(JSON.stringify({
            success: true,
            message: 'E-posta başarıyla gönderildi (Resend API)',
            simulation: false
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200
          });
        } else {
          throw new Error(`Resend API Error: ${resendResponse.status}`);
        }
      } catch (resendError) {
        console.error('❌ Resend API hatası:', resendError);
        
        // Son çare: Simülasyon modu
        console.log('📧 Tüm SMTP yöntemleri başarısız, simülasyon moduna geçiliyor');
        return new Response(JSON.stringify({
          success: true,
          message: 'E-posta simülasyon modunda gönderildi (SMTP hatası)',
          simulation: true,
          error: smtpError.message,
          emailData: { to, subject, from }
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        });
      }
    }

  } catch (error) {
    console.error('❌ E-posta gönderme hatası:', error)
    
    return new Response(JSON.stringify({ 
      success: false, 
      error: error.message || 'E-posta gönderilemedi',
      details: error.toString()
    }), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500 
    })
  }
}) 