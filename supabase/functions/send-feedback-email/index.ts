import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { SmtpClient } from "https://deno.land/x/smtp@v0.7.0/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders
    });
  }

  try {
    const { to, subject, html, text, from = "noreply@budgiebreedingtracker.com" } = await req.json();
    console.log("📧 E-posta gönderme isteği alındı:", {
      to,
      subject,
      from
    });

    const smtpHost = Deno.env.get("SMTP_HOST");
    const smtpPort = Number(Deno.env.get("SMTP_PORT"));
    const smtpUsername = Deno.env.get("SMTP_USERNAME");
    const smtpPassword = Deno.env.get("SMTP_PASSWORD");

    if (!smtpHost || !smtpPort || !smtpUsername || !smtpPassword) {
      console.log("📧 SMTP ayarları eksik, simülasyon modunda çalışıyor:", {
        smtpHost: smtpHost ? "SET" : "MISSING",
        smtpPort: smtpPort ? "SET" : "MISSING",
        smtpUsername: smtpUsername ? "SET" : "MISSING",
        smtpPassword: smtpPassword ? "SET" : "MISSING"
      });
      return new Response(JSON.stringify({
        success: true,
        message: "E-posta simülasyon modunda gönderildi (SMTP ayarları eksik)",
        simulation: true,
        emailData: {
          to,
          subject,
          from
        }
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    }

    console.log("✅ SMTP ayarları mevcut, Gmail SMTP üzerinden gönderiliyor...");
    
    try {
      const client = new SmtpClient();
      await client.connectTLS({
        hostname: smtpHost,
        port: smtpPort,
        username: smtpUsername,
        password: smtpPassword
      });
      
      await client.send({
        from,
        to,
        subject,
        content: text || "",
        html
      });
      
      await client.close();
      console.log("✅ E-posta başarıyla gönderildi (Gmail)");
      
      return new Response(JSON.stringify({
        success: true,
        message: "E-posta başarıyla gönderildi (Gmail SMTP)",
        simulation: false
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    } catch (smtpError) {
      console.error("❌ SMTP hatası:", smtpError);
      console.log(" Alternatif yöntem: Resend API deneniyor...");
      
      try {
        const resendResponse = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY") || "re_123456789"}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            from,
            to,
            subject,
            html,
            text
          })
        });
        
        if (resendResponse.ok) {
          console.log("✅ E-posta Resend API ile başarıyla gönderildi");
          return new Response(JSON.stringify({
            success: true,
            message: "E-posta başarıyla gönderildi (Resend API)",
            simulation: false
          }), {
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            },
            status: 200
          });
        } else {
          throw new Error(`Resend API Error: ${resendResponse.status}`);
        }
      } catch (resendError) {
        console.error("❌ Resend API hatası:", resendError);
        return new Response(JSON.stringify({
          success: true,
          message: "E-posta simülasyon modunda gönderildi (SMTP & Resend başarısız)",
          simulation: true,
          error: smtpError.message,
          emailData: {
            to,
            subject,
            from
          }
        }), {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          },
          status: 200
        });
      }
    }
  } catch (error) {
    console.error("❌ E-posta gönderme hatası:", error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message || "E-posta gönderilemedi",
      details: error.toString()
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      },
      status: 500
    });
  }
}); 