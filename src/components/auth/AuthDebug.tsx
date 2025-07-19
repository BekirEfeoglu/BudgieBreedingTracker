import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { AlertTriangle, CheckCircle, Info, RefreshCw, Trash2, HelpCircle } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { validateEmail, validatePassword, rateLimitCheck } from '@/utils/inputSanitization';

export const AuthDebug = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [loading, setLoading] = useState(false);
  const [debugInfo, setDebugInfo] = useState<string[]>([]);
  const [connectionStatus, setConnectionStatus] = useState<'checking' | 'connected' | 'error'>('checking');

  const addDebugInfo = (message: string) => {
    const timestamp = new Date().toLocaleTimeString();
    setDebugInfo(prev => [`[${timestamp}] ${message}`, ...prev.slice(0, 19)]);
  };

  const testConnection = async () => {
    setConnectionStatus('checking');
    addDebugInfo('🔍 Supabase bağlantısı test ediliyor...');
    
    try {
      const { data, error } = await supabase.from('profiles').select('count').limit(1);
      
      if (error) {
        setConnectionStatus('error');
        addDebugInfo(`❌ Bağlantı hatası: ${error.message}`);
      } else {
        setConnectionStatus('connected');
        addDebugInfo('✅ Supabase bağlantısı başarılı');
      }
    } catch (error: any) {
      setConnectionStatus('error');
      addDebugInfo(`💥 Bağlantı hatası: ${error.message}`);
    }
  };

  const validateInputs = () => {
    addDebugInfo('🔍 Girdi doğrulaması yapılıyor...');
    
    // Email validation
    const isEmailValid = validateEmail(email);
    addDebugInfo(`📧 E-posta doğrulaması: ${isEmailValid ? '✅ Geçerli' : '❌ Geçersiz'}`);
    
    // Password validation
    const passwordValidation = validatePassword(password);
    addDebugInfo(`🔐 Şifre doğrulaması: ${passwordValidation.isValid ? '✅ Geçerli' : '❌ Geçersiz'}`);
    
    if (!passwordValidation.isValid) {
      passwordValidation.errors.forEach(error => {
        addDebugInfo(`   - ${error}`);
      });
    }
    
    // Rate limiting check
    const canSignUp = rateLimitCheck('signup', 5, 60 * 60 * 1000); // 5 attempts per hour
    addDebugInfo(`⏱️ Rate limit kontrolü: ${canSignUp ? '✅ İzin veriliyor' : '❌ Engellendi'}`);
    
    return isEmailValid && passwordValidation.isValid && canSignUp;
  };

  const testSignUp = async () => {
    if (!email || !password) {
      toast({
        title: 'Eksik Bilgi',
        description: 'E-posta ve şifre gerekli.',
        variant: 'destructive'
      });
      return;
    }

    setLoading(true);
    addDebugInfo('🔄 Kayıt işlemi başlatılıyor...');
    addDebugInfo(`📧 E-posta: ${email}`);
    addDebugInfo(`🔐 Şifre uzunluğu: ${password.length}`);
    addDebugInfo(`👤 Ad: ${firstName || 'Boş'}`);
    addDebugInfo(`👤 Soyad: ${lastName || 'Boş'}`);
    
    // Input validation
    if (!validateInputs()) {
      addDebugInfo('❌ Girdi doğrulaması başarısız');
      setLoading(false);
      return;
    }
    
    try {
      addDebugInfo('📡 Supabase auth.signUp çağrılıyor...');
      
      // Her zaman production URL'ini kullan
      const redirectUrl = 'https://www.budgiebreedingtracker.com/';
      
      addDebugInfo(`🌐 Redirect URL: ${redirectUrl}`);
      addDebugInfo(`🏭 Environment: Production (forced)`);
      
      const { data, error } = await supabase.auth.signUp({
        email: email.toLowerCase().trim(),
        password,
        options: {
          emailRedirectTo: redirectUrl,
          data: {
            first_name: firstName?.trim() || 'Test',
            last_name: lastName?.trim() || 'Kullanıcı',
          },
        },
      });

      addDebugInfo('📡 Supabase yanıtı alındı');
      addDebugInfo(`📊 Veri var mı: ${data ? 'Evet' : 'Hayır'}`);
      addDebugInfo(`❌ Hata var mı: ${error ? 'Evet' : 'Hayır'}`);

      if (error) {
        addDebugInfo(`❌ Kayıt hatası: ${error.message}`);
        addDebugInfo(`📋 Hata kodu: ${error.status || 'N/A'}`);
        addDebugInfo(`🔍 Hata tipi: ${error.name || 'N/A'}`);
        
        // E-posta onayı gerekli mesajı başarı mesajı olarak göster
        if (error.message.includes('E-posta onayı gerekli')) {
          addDebugInfo('✅ Kayıt başarılı - E-posta onayı gerekli');
          addDebugInfo('📧 Kullanıcıya başarı mesajı gösteriliyor');
          toast({
            title: 'Kayıt Başarılı!',
            description: error.message,
          });
        } else {
          addDebugInfo('❌ Gerçek kayıt hatası - Kullanıcıya hata mesajı gösteriliyor');
          
          // Detaylı hata analizi
          const errorMsg = error.message || '';
          const errorStatus = error.status || 0;
          
          if (errorMsg.includes('already registered') || errorMsg.includes('already exists')) {
            addDebugInfo('💡 Çözüm: Bu e-posta zaten kayıtlı, giriş yapmayı deneyin');
          } else if (errorMsg.includes('weak password')) {
            addDebugInfo('💡 Çözüm: Daha güçlü bir şifre seçin (en az 6 karakter, 2 farklı karakter türü)');
          } else if (errorMsg.includes('network') || errorMsg.includes('fetch')) {
            addDebugInfo('💡 Çözüm: İnternet bağlantınızı kontrol edin');
          } else if (errorStatus === 429) {
            addDebugInfo('💡 Çözüm: Çok fazla deneme, 1 saat bekleyin');
          } else if (errorMsg.includes('Invalid login credentials')) {
            addDebugInfo('💡 Çözüm: Bu hata kayıt sırasında olmamalı, giriş işlemi karışmış olabilir');
          }
          
          toast({
            title: 'Kayıt Hatası',
            description: error.message,
            variant: 'destructive'
          });
        }
      } else {
        addDebugInfo('✅ Kayıt başarılı!');
        addDebugInfo(`👤 Kullanıcı ID: ${data.user?.id || 'N/A'}`);
        addDebugInfo(`📧 Doğrulama gerekli: ${data.user?.email_confirmed_at ? 'Hayır' : 'Evet'}`);
        addDebugInfo(`🔑 Oturum oluşturuldu: ${data.session ? 'Evet' : 'Hayır'}`);
        
        // E-posta onayı olmadan oturum açmaya çalış
        if (data.user && !data.session) {
          addDebugInfo('🔐 E-posta onayı olmadan oturum açmaya çalışılıyor...');
          
          // Geçici olarak otomatik giriş denemesini devre dışı bırak
          addDebugInfo('⚠️ Otomatik giriş denemesi geçici olarak devre dışı');
          addDebugInfo('💡 E-posta onayı gerekli, e-posta kutunuzu kontrol edin');
          
          /*
          const { error: signInError } = await supabase.auth.signInWithPassword({
            email: email.toLowerCase().trim(),
            password,
          });
          
          if (signInError) {
            addDebugInfo(`❌ Otomatik giriş başarısız: ${signInError.message}`);
            addDebugInfo('💡 E-posta onayı gerekli, e-posta kutunuzu kontrol edin');
          } else {
            addDebugInfo('✅ Otomatik giriş başarılı!');
          }
          */
        }
        
        toast({
          title: 'Kayıt Başarılı!',
          description: 'Hesabınız oluşturuldu. E-posta adresinizi kontrol edin.',
        });
      }
    } catch (error: any) {
      addDebugInfo(`💥 Beklenmeyen hata: ${error.message}`);
      addDebugInfo(`🔍 Hata tipi: ${error.name || 'Unknown'}`);
      addDebugInfo(`📋 Stack: ${error.stack?.slice(0, 200)}...`);
      
      toast({
        title: 'Beklenmeyen Hata',
        description: error.message,
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const bypassRateLimit = () => {
    // Tüm storage'ları temizle
    localStorage.clear();
    sessionStorage.clear();
    
    // Cookies'i temizle
    document.cookie.split(";").forEach(function(c) { 
      document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/"); 
    });
    
    // Supabase session'ı temizle
    supabase.auth.signOut().then(() => {
      addDebugInfo('🚀 Rate limit bypass başlatıldı');
      addDebugInfo('🧹 Tüm storage temizlendi');
      addDebugInfo('🍪 Cookies temizlendi');
      addDebugInfo('🔐 Supabase session temizlendi');
      addDebugInfo('✅ Artık yeni kayıt denemesi yapabilirsiniz');
      addDebugInfo('💡 Öneri: Farklı e-posta adresi kullanın');
      addDebugInfo('🌐 Öneri: Farklı IP adresi (VPN/mobil veri) deneyin');
      addDebugInfo('📱 Öneri: Mobil veri ile deneyin');
      
      toast({
        title: 'Rate Limit Bypass',
        description: 'Tüm veriler temizlendi. Artık yeni kayıt denemesi yapabilirsiniz.',
      });
    });
  };

  const clearRateLimit = () => {
    // Local rate limit temizleme
    localStorage.removeItem('rateLimit_signup');
    localStorage.removeItem('rateLimit_signin');
    localStorage.removeItem('rateLimit_reset');
    
    // Tüm localStorage'ı temizle (Supabase rate limit için)
    Object.keys(localStorage).forEach(key => {
      if (key.includes('supabase') || key.includes('rateLimit') || key.includes('auth')) {
        localStorage.removeItem(key);
      }
    });
    
    // Session storage'ı da temizle
    sessionStorage.clear();
    
    // Supabase session temizleme (rate limit'i sıfırlamak için)
    supabase.auth.signOut().then(() => {
      addDebugInfo('🧹 Rate limit temizlendi');
      addDebugInfo('🔐 Supabase session temizlendi');
      addDebugInfo('🗑️ Tüm localStorage temizlendi');
      addDebugInfo('🗑️ Session storage temizlendi');
      addDebugInfo('✅ Artık yeni kayıt denemesi yapabilirsiniz');
      addDebugInfo('💡 Öneri: Farklı e-posta adresi kullanın');
      addDebugInfo('🌐 Öneri: Farklı IP adresi (VPN/mobil veri) deneyin');
      console.log('🧹 Rate limit temizlendi - localStorage:', {
        signup: localStorage.getItem('rateLimit_signup'),
        signin: localStorage.getItem('rateLimit_signin'),
        reset: localStorage.getItem('rateLimit_reset')
      });
      toast({
        title: 'Rate Limit Temizlendi',
        description: 'Artık yeni kayıt denemesi yapabilirsiniz.',
      });
    });
  };

  const createGmailAccount = () => {
    const timestamp = Date.now();
    const randomSuffix = Math.random().toString(36).substring(2, 8);
    const testEmail = `test${timestamp}${randomSuffix}@gmail.com`;
    const testPassword = 'Test123!';
    
    setEmail(testEmail);
    setPassword(testPassword);
    setFirstName('Test');
    setLastName('Gmail');
    
    addDebugInfo('📧 Gmail test hesabı oluşturuldu:');
    addDebugInfo(`📧 E-posta: ${testEmail}`);
    addDebugInfo(`🔐 Şifre: ${testPassword}`);
    addDebugInfo('💡 Gmail genellikle daha hızlı e-posta gönderir');
    addDebugInfo('📧 Gönderen: admin@budgiebreedingtracker.com');
  };

  const createOutlookAccount = () => {
    const timestamp = Date.now();
    const randomSuffix = Math.random().toString(36).substring(2, 8);
    const testEmail = `test${timestamp}${randomSuffix}@outlook.com`;
    const testPassword = 'Test123!';
    
    setEmail(testEmail);
    setPassword(testPassword);
    setFirstName('Test');
    setLastName('Outlook');
    
    addDebugInfo('📧 Outlook test hesabı oluşturuldu:');
    addDebugInfo(`📧 E-posta: ${testEmail}`);
    addDebugInfo(`🔐 Şifre: ${testPassword}`);
    addDebugInfo('💡 Outlook alternatif e-posta sağlayıcısı');
    addDebugInfo('📧 Gönderen: admin@budgiebreedingtracker.com');
  };

  const createTestAccount = () => {
    const timestamp = Date.now();
    const randomSuffix = Math.random().toString(36).substring(2, 8);
    const testEmail = `test${timestamp}${randomSuffix}@example.com`;
    const testPassword = 'Test123!';
    
    setEmail(testEmail);
    setPassword(testPassword);
    setFirstName('Test');
    setLastName('Kullanıcı');
    
    addDebugInfo('🧪 Test hesabı bilgileri oluşturuldu:');
    addDebugInfo(`📧 E-posta: ${testEmail}`);
    addDebugInfo(`🔐 Şifre: ${testPassword}`);
    addDebugInfo(`👤 Ad: Test`);
    addDebugInfo(`👤 Soyad: Kullanıcı`);
    addDebugInfo('💡 Şimdi "Test Kaydı" butonuna tıklayın');
    addDebugInfo('⚠️ Not: E-posta onayı gerekebilir');
    addDebugInfo('🔄 Rate limit sorunu yaşarsanız "Rate Limit Bypass" butonunu kullanın');
    addDebugInfo('🌐 Yönlendirme URL: https://www.budgiebreedingtracker.com/');
  };

  const checkEmailConfirmation = async () => {
    if (!email) {
      toast({
        title: 'E-posta Gerekli',
        description: 'Önce e-posta adresini girin.',
        variant: 'destructive'
      });
      return;
    }

    setLoading(true);
    addDebugInfo('🔍 E-posta onay durumu kontrol ediliyor...');
    
    try {
      // Kullanıcıyı e-posta ile ara
      const { data, error } = await supabase.auth.admin.listUsers();
      
      if (error) {
        addDebugInfo(`❌ Kullanıcı listesi alınamadı: ${error.message}`);
        return;
      }

      const user = data.users.find(u => u.email === email.toLowerCase().trim());
      
      if (!user) {
        addDebugInfo('❌ Bu e-posta ile kayıtlı kullanıcı bulunamadı');
        return;
      }

      addDebugInfo(`👤 Kullanıcı bulundu: ${user.id}`);
      addDebugInfo(`📧 E-posta: ${user.email}`);
      addDebugInfo(`✅ E-posta onaylandı mı: ${user.email_confirmed_at ? 'Evet' : 'Hayır'}`);
      addDebugInfo(`📅 Onay tarihi: ${user.email_confirmed_at || 'Onaylanmamış'}`);
      addDebugInfo(`📅 Kayıt tarihi: ${user.created_at}`);
      addDebugInfo(`🔐 Son giriş: ${user.last_sign_in_at || 'Hiç giriş yapmamış'}`);

      if (!user.email_confirmed_at) {
        addDebugInfo('⚠️ E-posta henüz onaylanmamış!');
        addDebugInfo('💡 Çözüm önerileri:');
        addDebugInfo('   1. Spam/Junk klasörünü kontrol edin');
        addDebugInfo('   2. E-posta adresini doğru yazdığınızdan emin olun');
        addDebugInfo('   3. Birkaç dakika bekleyin (e-posta gecikmeli gelebilir)');
        addDebugInfo('   4. Farklı bir e-posta adresi deneyin');
      } else {
        addDebugInfo('✅ E-posta onaylanmış! Giriş yapabilirsiniz.');
      }

    } catch (error: any) {
      addDebugInfo(`💥 Hata: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const resendConfirmationEmail = async () => {
    if (!email) {
      toast({
        title: 'E-posta Gerekli',
        description: 'Önce e-posta adresini girin.',
        variant: 'destructive'
      });
      return;
    }

    setLoading(true);
    addDebugInfo('📧 Onay e-postası yeniden gönderiliyor...');
    
    try {
      const { error } = await supabase.auth.resend({
        type: 'signup',
        email: email.toLowerCase().trim(),
        options: {
          emailRedirectTo: 'https://www.budgiebreedingtracker.com/'
        }
      });

      if (error) {
        addDebugInfo(`❌ E-posta gönderilemedi: ${error.message}`);
        toast({
          title: 'Hata',
          description: error.message,
          variant: 'destructive'
        });
      } else {
        addDebugInfo('✅ Onay e-postası yeniden gönderildi!');
        addDebugInfo('📧 E-posta kutunuzu kontrol edin');
        addDebugInfo('📁 Spam/Junk klasörünü de kontrol edin');
        toast({
          title: 'E-posta Gönderildi',
          description: 'Onay e-postası yeniden gönderildi. E-posta kutunuzu kontrol edin.',
        });
      }
    } catch (error: any) {
      addDebugInfo(`💥 Hata: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const clearDebug = () => {
    setDebugInfo([]);
  };

  const clearRateLimits = () => {
    localStorage.removeItem('rateLimit_signup');
    localStorage.removeItem('rateLimit_login');
    localStorage.removeItem('rateLimit_reset');
    addDebugInfo('🧹 Rate limit verileri temizlendi');
  };

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            🚨 ACİL: E-posta Yönlendirme Sorunu
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-start gap-2">
            <AlertTriangle className="w-4 h-4 text-red-500 mt-0.5" />
            <div>
              <strong>E-posta hala localhost'a yönlendiriyor!</strong>
              <p className="text-sm text-muted-foreground mt-1">
                Supabase Dashboard'da Site URL ayarını güncellemeniz gerekiyor:
              </p>
              <ol className="text-sm text-muted-foreground ml-4 mt-1 list-decimal">
                <li>Supabase Dashboard {'>>'} Authentication {'>>'} Settings</li>
                <li>"Site URL" alanını bulun</li>
                <li>Mevcut değer: http://localhost:5173 (muhtemelen)</li>
                <li>Yeni değer: https://www.budgiebreedingtracker.com</li>
                <li>"Save" butonuna tıklayın</li>
                <li>Yeni test hesabı oluşturun</li>
              </ol>
              <p className="text-xs text-red-600 mt-2 font-bold">
                ⚠️ Bu ayar yapılmadan e-posta doğru adrese yönlendirmeyecek!
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            🔧 Kayıt İşlemi Debug
            <Badge variant={connectionStatus === 'connected' ? 'default' : connectionStatus === 'error' ? 'destructive' : 'secondary'}>
              {connectionStatus === 'connected' ? 'Bağlı' : connectionStatus === 'error' ? 'Hata' : 'Kontrol ediliyor'}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2 flex-wrap">
            <Button onClick={testConnection} variant="outline" size="sm">
              <RefreshCw className="w-4 h-4 mr-2" />
              Bağlantıyı Test Et
            </Button>
            <Button onClick={clearRateLimit} variant="outline" size="sm">
              <Trash2 className="w-4 h-4 mr-2" />
              Rate Limit Temizle
            </Button>
            <Button onClick={bypassRateLimit} variant="outline" size="sm">
              <RefreshCw className="w-4 h-4 mr-2" />
              Rate Limit Bypass
            </Button>
            <Button onClick={createGmailAccount} variant="outline" size="sm">
              📧 Gmail Test Hesabı
            </Button>
            <Button onClick={createOutlookAccount} variant="outline" size="sm">
              📧 Outlook Test Hesabı
            </Button>
            <Button onClick={createTestAccount} variant="outline" size="sm">
              🧪 Test Hesabı Oluştur
            </Button>
            <Button onClick={checkEmailConfirmation} variant="outline" size="sm" disabled={loading}>
              🔍 E-posta Onayını Kontrol Et
            </Button>
            <Button onClick={resendConfirmationEmail} variant="outline" size="sm" disabled={loading}>
              📧 Onay E-postasını Yeniden Gönder
            </Button>
          </div>
          
          <Separator />
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="email">E-posta</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="test@example.com"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Şifre</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="En az 6 karakter"
              />
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="firstName">Ad</Label>
              <Input
                id="firstName"
                type="text"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                placeholder="Adınız"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="lastName">Soyad</Label>
              <Input
                id="lastName"
                type="text"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                placeholder="Soyadınız"
              />
            </div>
          </div>

          <Button 
            onClick={testSignUp} 
            disabled={loading || !email || !password}
            className="w-full"
          >
            {loading ? (
              <>
                <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
                Test Ediliyor...
              </>
            ) : (
              'Kayıt İşlemini Test Et'
            )}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            📋 Debug Bilgileri
            <Button onClick={clearDebug} variant="outline" size="sm">
              Temizle
            </Button>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2 max-h-96 overflow-y-auto">
            {debugInfo.length === 0 ? (
              <div className="text-center text-muted-foreground py-8">
                <Info className="w-8 h-8 mx-auto mb-2" />
                Henüz debug bilgisi yok. Test işlemi başlatın.
              </div>
            ) : (
              debugInfo.map((info, index) => (
                <div key={index} className="text-sm font-mono bg-muted p-2 rounded">
                  {info}
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>💡 Yardım</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-start gap-2">
            <AlertTriangle className="w-4 h-4 text-amber-500 mt-0.5" />
            <div>
              <strong>Şifre Gereksinimleri (Güncellendi!):</strong>
              <ul className="text-sm text-muted-foreground ml-4 mt-1">
                <li>• En az 6 karakter</li>
                <li>• En az 2 farklı karakter türü:</li>
                <li>  - Büyük harf (A-Z)</li>
                <li>  - Küçük harf (a-z)</li>
                <li>  - Rakam (0-9)</li>
                <li>  - Özel karakter (!@#$%^&*)</li>
              </ul>
              <p className="text-xs text-blue-600 mt-1">
                Örnek: Test123, MyPass1, Secure!
              </p>
            </div>
          </div>
          
          <div className="flex items-start gap-2">
            <CheckCircle className="w-4 h-4 text-green-500 mt-0.5" />
            <div>
              <strong>✅ Başarılı Kayıt:</strong>
              <p className="text-sm text-muted-foreground mt-1">
                E-posta doğrulama bağlantısı gönderilir. E-posta kutunuzu kontrol edin.
              </p>
              <p className="text-xs text-blue-600 mt-1">
                🌐 Yönlendirme URL: https://www.budgiebreedingtracker.com/
              </p>
              <p className="text-xs text-purple-600 mt-1">
                📧 Gönderen: admin@budgiebreedingtracker.com
              </p>
            </div>
          </div>
          
          <div className="flex items-start gap-2">
            <Info className="w-4 h-4 text-blue-500 mt-0.5" />
            <div>
              <strong>Rate Limiting (Güncellendi!):</strong>
              <p className="text-sm text-muted-foreground mt-1">
                Saatte en fazla 5 kayıt denemesi yapabilirsiniz (3'ten 5'e çıkarıldı). Limit aşılırsa "Rate Limit Temizle" butonunu kullanın.
              </p>
            </div>
          </div>
          
          <div className="flex items-start gap-2">
            <HelpCircle className="w-4 h-4 text-purple-500 mt-0.5" />
            <div>
              <strong>Yaygın Sorunlar:</strong>
              <ul className="text-sm text-muted-foreground ml-4 mt-1">
                <li>• E-posta zaten kayıtlı → Giriş yapmayı deneyin</li>
                <li>• Şifre çok zayıf → En az 6 karakter + 2 farklı tür</li>
                <li>• Bağlantı hatası → İnterneti kontrol edin</li>
                <li>• Çok fazla deneme → 1 saat bekleyin</li>
                <li>• Onay e-postası gelmiyor → Spam klasörünü kontrol edin</li>
                <li>• E-posta onayı gerekli → "Onay E-postasını Yeniden Gönder" kullanın</li>
              </ul>
            </div>
          </div>

          <div className="flex items-start gap-2">
            <AlertTriangle className="w-4 h-4 text-orange-500 mt-0.5" />
            <div>
              <strong>🚫 Rate Limit Sorunları:</strong>
              <p className="text-sm text-muted-foreground mt-1">
                "email rate limit exceeded" hatası alıyorsanız:
              </p>
              <ol className="text-sm text-muted-foreground ml-4 mt-1 list-decimal">
                <li>"Rate Limit Bypass" butonunu kullanın</li>
                <li>Farklı e-posta adresi deneyin (Gmail/Outlook)</li>
                <li>Farklı IP adresi kullanın (VPN/mobil veri)</li>
                <li>1 saat bekleyin (Supabase rate limit)</li>
                <li>Tarayıcıyı kapatıp açın</li>
                <li>Gizli/incognito modda deneyin</li>
              </ol>
            </div>
          </div>

          <div className="flex items-start gap-2">
            <AlertTriangle className="w-4 h-4 text-red-500 mt-0.5" />
            <div>
              <strong>🌐 Yönlendirme URL Sorunları:</strong>
              <p className="text-sm text-muted-foreground mt-1">
                E-posta hala localhost'a yönlendiriyorsa:
              </p>
              <ol className="text-sm text-muted-foreground ml-4 mt-1 list-decimal">
                <li>Supabase Dashboard {'>>'} Authentication {'>>'} Settings</li>
                <li>"Site URL" alanını kontrol edin</li>
                <li>Değeri şu şekilde güncelleyin: https://www.budgiebreedingtracker.com</li>
                <li>"Redirect URLs" bölümüne şu URL'leri ekleyin:</li>
                <li className="ml-4">• https://www.budgiebreedingtracker.com</li>
                <li className="ml-4">• https://www.budgiebreedingtracker.com/</li>
                <li className="ml-4">• https://www.budgiebreedingtracker.com/auth/callback</li>
                <li>"Save" butonuna tıklayın</li>
                <li>Yeni test hesabı oluşturun</li>
              </ol>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}; 