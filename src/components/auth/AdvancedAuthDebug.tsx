import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { AlertTriangle, CheckCircle, Info, RefreshCw, Trash2, HelpCircle, Wifi, WifiOff, Globe, Shield, Mail, Lock } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { validateEmail, validatePassword, clearAllRateLimits } from '@/utils/inputSanitization';

export const AdvancedAuthDebug = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [loading, setLoading] = useState(false);
  const [debugInfo, setDebugInfo] = useState<string[]>([]);
  const [connectionStatus, setConnectionStatus] = useState<'checking' | 'connected' | 'error'>('checking');
  const [networkInfo, setNetworkInfo] = useState<any>({});
  const [supabaseInfo, setSupabaseInfo] = useState<any>({});

  const addDebugInfo = (message: string, type: 'info' | 'success' | 'error' | 'warning' = 'info') => {
    const timestamp = new Date().toLocaleTimeString();
    const icon = type === 'success' ? '✅' : type === 'error' ? '❌' : type === 'warning' ? '⚠️' : 'ℹ️';
    setDebugInfo(prev => [`[${timestamp}] ${icon} ${message}`, ...prev.slice(0, 49)]);
  };

  useEffect(() => {
    checkNetworkInfo();
    checkSupabaseInfo();
    testConnection();
  }, []);

  const checkNetworkInfo = async () => {
    try {
      // IP adresi kontrolü
      const ipResponse = await fetch('https://api.ipify.org?format=json');
      const ipData = await ipResponse.json();
      
      // Network bilgileri
      const networkData = {
        ip: ipData.ip,
        userAgent: navigator.userAgent,
        language: navigator.language,
        platform: navigator.platform,
        cookieEnabled: navigator.cookieEnabled,
        online: navigator.onLine,
        connection: (navigator as any).connection?.effectiveType || 'unknown'
      };
      
      setNetworkInfo(networkData);
      addDebugInfo(`🌐 IP Adresi: ${ipData.ip}`, 'info');
      addDebugInfo(`📱 Platform: ${navigator.platform}`, 'info');
      addDebugInfo(`🌍 Dil: ${navigator.language}`, 'info');
      addDebugInfo(`📶 Bağlantı: ${networkData.connection}`, 'info');
    } catch (error) {
      addDebugInfo('❌ Network bilgileri alınamadı', 'error');
    }
  };

  const checkSupabaseInfo = () => {
    const supabaseData = {
      url: supabase.supabaseUrl,
      key: supabase.supabaseKey?.slice(0, 20) + '...',
      auth: supabase.auth,
      storage: localStorage.getItem('supabase.auth.token') ? 'Mevcut' : 'Yok'
    };
    
    setSupabaseInfo(supabaseData);
    addDebugInfo(`🔗 Supabase URL: ${supabaseData.url}`, 'info');
    addDebugInfo(`🔑 Supabase Key: ${supabaseData.key}`, 'info');
    addDebugInfo(`💾 Local Storage: ${supabaseData.storage}`, 'info');
  };

  const testConnection = async () => {
    setConnectionStatus('checking');
    addDebugInfo('🔍 Supabase bağlantısı test ediliyor...', 'info');
    
    try {
      const startTime = Date.now();
      const { data, error } = await supabase.from('profiles').select('count').limit(1);
      const endTime = Date.now();
      
      if (error) {
        setConnectionStatus('error');
        addDebugInfo(`❌ Bağlantı hatası: ${error.message}`, 'error');
        addDebugInfo(`📊 Hata kodu: ${error.code}`, 'error');
        addDebugInfo(`🔍 Hata detayı: ${error.details}`, 'error');
      } else {
        setConnectionStatus('connected');
        addDebugInfo(`✅ Bağlantı başarılı (${endTime - startTime}ms)`, 'success');
      }
    } catch (error: any) {
      setConnectionStatus('error');
      addDebugInfo(`💥 Beklenmeyen hata: ${error.message}`, 'error');
    }
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
    addDebugInfo('🔄 Gelişmiş kayıt testi başlatılıyor...', 'info');
    addDebugInfo(`📧 E-posta: ${email}`, 'info');
    addDebugInfo(`🔐 Şifre uzunluğu: ${password.length}`, 'info');
    addDebugInfo(`👤 Ad: ${firstName || 'Boş'}`, 'info');
    addDebugInfo(`👤 Soyad: ${lastName || 'Boş'}`, 'info');
    
    // Girdi doğrulaması
    const isEmailValid = validateEmail(email);
    const passwordValidation = validatePassword(password);
    
    addDebugInfo(`📧 E-posta doğrulaması: ${isEmailValid ? '✅ Geçerli' : '❌ Geçersiz'}`, isEmailValid ? 'success' : 'error');
    addDebugInfo(`🔐 Şifre doğrulaması: ${passwordValidation.isValid ? '✅ Geçerli' : '❌ Geçersiz'}`, passwordValidation.isValid ? 'success' : 'error');
    
    if (!passwordValidation.isValid) {
      passwordValidation.errors.forEach(error => {
        addDebugInfo(`   - ${error}`, 'error');
      });
    }
    
    try {
      addDebugInfo('📡 Supabase auth.signUp çağrılıyor...', 'info');
      
      const startTime = Date.now();
      const { data, error } = await supabase.auth.signUp({
        email: email.toLowerCase().trim(),
        password,
        options: {
          emailRedirectTo: 'https://www.budgiebreedingtracker.com/',
          data: {
            first_name: firstName?.trim() || 'Test',
            last_name: lastName?.trim() || 'Kullanıcı',
          },
        },
      });
      const endTime = Date.now();
      
      addDebugInfo(`⏱️ İşlem süresi: ${endTime - startTime}ms`, 'info');
      addDebugInfo(`📊 Veri var mı: ${data ? 'Evet' : 'Hayır'}`, 'info');
      addDebugInfo(`❌ Hata var mı: ${error ? 'Evet' : 'Hayır'}`, error ? 'error' : 'success');

      if (error) {
        addDebugInfo(`❌ Kayıt hatası: ${error.message}`, 'error');
        addDebugInfo(`📋 Hata kodu: ${error.status || 'N/A'}`, 'error');
        addDebugInfo(`🔍 Hata tipi: ${error.name || 'N/A'}`, 'error');
        
        // Detaylı hata analizi
        if (error.status === 429) {
          addDebugInfo('🚨 RATE LIMIT HATASI TESPİT EDİLDİ!', 'error');
          addDebugInfo('💡 Çözüm 1: VPN kullanın', 'warning');
          addDebugInfo('💡 Çözüm 2: Mobil veri kullanın', 'warning');
          addDebugInfo('💡 Çözüm 3: 1 saat bekleyin', 'warning');
          addDebugInfo('💡 Çözüm 4: Farklı e-posta kullanın', 'warning');
        } else if (error.message.includes('already registered')) {
          addDebugInfo('💡 Bu e-posta zaten kayıtlı, giriş yapmayı deneyin', 'warning');
        } else if (error.message.includes('weak password')) {
          addDebugInfo('💡 Daha güçlü şifre seçin', 'warning');
        } else if (error.message.includes('network')) {
          addDebugInfo('💡 İnternet bağlantınızı kontrol edin', 'warning');
        }
        
        toast({
          title: 'Kayıt Hatası',
          description: error.message,
          variant: 'destructive'
        });
      } else {
        addDebugInfo('✅ Kayıt başarılı!', 'success');
        addDebugInfo(`👤 Kullanıcı ID: ${data.user?.id || 'N/A'}`, 'success');
        addDebugInfo(`📧 Doğrulama gerekli: ${data.user?.email_confirmed_at ? 'Hayır' : 'Evet'}`, 'info');
        addDebugInfo(`🔑 Oturum oluşturuldu: ${data.session ? 'Evet' : 'Hayır'}`, 'info');
        
        if (data.user && !data.session) {
          addDebugInfo('📧 E-posta onayı gerekli, e-posta kutunuzu kontrol edin', 'warning');
        }
        
        toast({
          title: 'Kayıt Başarılı!',
          description: 'Hesabınız oluşturuldu. E-posta adresinizi kontrol edin.',
        });
      }
    } catch (error: any) {
      addDebugInfo(`💥 Beklenmeyen hata: ${error.message}`, 'error');
      addDebugInfo(`🔍 Hata tipi: ${error.name || 'Unknown'}`, 'error');
      
      toast({
        title: 'Beklenmeyen Hata',
        description: error.message,
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const clearAllData = () => {
    // Tüm storage'ları temizle
    localStorage.clear();
    sessionStorage.clear();
    
    // Cookies'i temizle
    document.cookie.split(";").forEach(function(c) { 
      document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/"); 
    });
    
    // Supabase session'ı temizle
    supabase.auth.signOut().then(() => {
      addDebugInfo('🧹 Tüm veriler temizlendi', 'success');
      addDebugInfo('🍪 Cookies temizlendi', 'success');
      addDebugInfo('🔐 Supabase session temizlendi', 'success');
      addDebugInfo('✅ Artık yeni kayıt denemesi yapabilirsiniz', 'success');
      
      toast({
        title: 'Veriler Temizlendi',
        description: 'Tüm veriler temizlendi. Artık yeni kayıt denemesi yapabilirsiniz.',
      });
    });
  };

  const testWithDifferentEmail = () => {
    const testEmails = [
      `test${Date.now()}@gmail.com`,
      `user${Date.now()}@outlook.com`,
      `demo${Date.now()}@yahoo.com`,
      `temp${Date.now()}@hotmail.com`
    ];
    
    const randomEmail = testEmails[Math.floor(Math.random() * testEmails.length)];
    setEmail(randomEmail);
    setPassword('Test123456');
    setFirstName('Test');
    setLastName('Kullanıcı');
    
    addDebugInfo(`📧 Test e-postası ayarlandı: ${randomEmail}`, 'info');
    addDebugInfo(`🔐 Test şifresi ayarlandı: Test123456`, 'info');
  };

  const clearDebug = () => {
    setDebugInfo([]);
  };

  return (
    <div className="max-w-4xl mx-auto p-4 space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="w-5 h-5" />
            Gelişmiş Auth Debug Paneli
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Network Bilgileri */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm flex items-center gap-2">
                  <Globe className="w-4 h-4" />
                  Network Bilgileri
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 text-xs">
                <div className="flex justify-between">
                  <span>IP Adresi:</span>
                  <Badge variant="outline">{networkInfo.ip || 'Yükleniyor...'}</Badge>
                </div>
                <div className="flex justify-between">
                  <span>Platform:</span>
                  <Badge variant="outline">{networkInfo.platform || 'N/A'}</Badge>
                </div>
                <div className="flex justify-between">
                  <span>Bağlantı:</span>
                  <Badge variant="outline">{networkInfo.connection || 'N/A'}</Badge>
                </div>
                <div className="flex justify-between">
                  <span>Online:</span>
                  <Badge variant={networkInfo.online ? "default" : "destructive"}>
                    {networkInfo.online ? 'Evet' : 'Hayır'}
                  </Badge>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm flex items-center gap-2">
                  <Shield className="w-4 h-4" />
                  Supabase Bilgileri
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 text-xs">
                <div className="flex justify-between">
                  <span>Bağlantı:</span>
                  <Badge variant={connectionStatus === 'connected' ? "default" : connectionStatus === 'error' ? "destructive" : "secondary"}>
                    {connectionStatus === 'connected' ? 'Bağlı' : connectionStatus === 'error' ? 'Hata' : 'Kontrol ediliyor'}
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span>URL:</span>
                  <Badge variant="outline" className="text-xs truncate max-w-32">
                    {supabaseInfo.url || 'N/A'}
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span>Local Storage:</span>
                  <Badge variant="outline">
                    {supabaseInfo.storage || 'N/A'}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Test Formu */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Test Formu</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="firstName">Ad</Label>
                  <Input
                    id="firstName"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    placeholder="Adınız"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName">Soyad</Label>
                  <Input
                    id="lastName"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    placeholder="Soyadınız"
                  />
                </div>
              </div>
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
              
              <div className="flex flex-wrap gap-2">
                <Button onClick={testSignUp} disabled={loading}>
                  {loading ? 'Test Ediliyor...' : 'Kayıt Test Et'}
                </Button>
                <Button variant="outline" onClick={testConnection}>
                  <RefreshCw className="w-4 h-4 mr-2" />
                  Bağlantı Test Et
                </Button>
                <Button variant="outline" onClick={testWithDifferentEmail}>
                  <Mail className="w-4 h-4 mr-2" />
                  Test E-postası
                </Button>
                <Button variant="outline" onClick={clearAllData}>
                  <Trash2 className="w-4 h-4 mr-2" />
                  Verileri Temizle
                </Button>
                <Button variant="outline" onClick={clearDebug}>
                  <RefreshCw className="w-4 h-4 mr-2" />
                  Debug Temizle
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Debug Log */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm flex items-center justify-between">
                <span>Debug Log</span>
                <Badge variant="outline">{debugInfo.length} mesaj</Badge>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="bg-gray-50 rounded-lg p-4 h-64 overflow-y-auto font-mono text-xs">
                {debugInfo.length === 0 ? (
                  <div className="text-gray-500 text-center py-8">
                    Henüz debug mesajı yok. Test başlatın...
                  </div>
                ) : (
                  debugInfo.map((message, index) => (
                    <div key={index} className="mb-1">
                      {message}
                    </div>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </CardContent>
      </Card>
    </div>
  );
}; 