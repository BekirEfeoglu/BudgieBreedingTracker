import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, cache-control, pragma, expires, connection, user-agent',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Public function - no authentication required
  console.log('📧 Edge Function çağrıldı:', req.method, req.url);
  console.log('🔑 Authorization header:', req.headers.get('Authorization') ? 'Present' : 'Missing');
  console.log('🔑 API Key header:', req.headers.get('apikey') ? 'Present' : 'Missing');
  
  // Public access - no authentication required
  // This function is designed to be called without authentication
  // Accept requests with or without authentication headers
  // Skip all authentication checks

  try {
    const body = await req.json()
    console.log('📨 Request body:', JSON.stringify(body, null, 2));
    
    const { feedbackData } = body
    
    // Validate input
    if (!feedbackData || !feedbackData.type || !feedbackData.title || !feedbackData.description) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Feedback data is required with type, title, and description' 
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400 
        }
      )
    }
    
    // SendGrid API key from environment
    const sendGridApiKey = Deno.env.get('SENDGRID_API_KEY')
    console.log('🔑 SendGrid API Key Length:', sendGridApiKey?.length || 0);
    
    if (!sendGridApiKey) {
      console.error('❌ SendGrid API key not found in environment variables');
      throw new Error('SendGrid API key not found in environment variables')
    }

    // Prepare email data
    const emailData = {
      personalizations: [
        {
          to: [{ email: 'admin@budgiebreedingtracker.com' }],
          subject: `[Geri Bildirim] ${feedbackData.type.toUpperCase()}: ${feedbackData.title}`,
        },
      ],
                   from: { email: 'noreply@sendgrid.net' },
      content: [
        {
          type: 'text/plain',
          value: createEmailBody(feedbackData),
        },
      ],
    }

    // Send email via SendGrid
    const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${sendGridApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(emailData),
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`SendGrid API error: ${response.status} - ${errorText}`)
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Email sent successfully' }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error sending email:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

function createEmailBody(feedbackData: any): string {
  const typeLabels = {
    bug: 'Hata Bildirimi',
    feature: 'Özellik Önerisi',
    improvement: 'İyileştirme Önerisi',
    general: 'Genel Geri Bildirim'
  }

  return `
Yeni bir geri bildirim alındı:

📋 TÜR: ${typeLabels[feedbackData.type] || feedbackData.type}
📝 BAŞLIK: ${feedbackData.title}
📄 AÇIKLAMA: ${feedbackData.description}
👤 KULLANICI: ${feedbackData.userName || 'Anonim'}
📧 E-POSTA: ${feedbackData.userEmail || 'Belirtilmemiş'}
🕒 TARİH: ${new Date().toLocaleString('tr-TR')}

---
Bu e-posta BudgieBreedingTracker uygulamasından otomatik olarak gönderilmiştir.
Yanıtlamak için: admin@budgiebreedingtracker.com
  `.trim()
} 