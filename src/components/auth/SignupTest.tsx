import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { AlertTriangle, CheckCircle, Info, RefreshCw, Trash2, HelpCircle, Mail, Lock, User } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { validateEmail, validatePassword } from '@/utils/inputSanitization';

export const SignupTest = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [loading, setLoading] = useState(false);
  const [debugInfo, setDebugInfo] = useState<string[]>([]);
  const [testResults, setTestResults] = useState<any[]>([]);

  const addDebugInfo = (message: string) => {
    const timestamp = new Date().toLocaleTimeString();
    setDebugInfo(prev => [`[${timestamp}] ${message}`, ...prev.slice(0, 19)]);
  };

  const addTestResult = (test: string, result: 'success' | 'error' | 'warning', message: string) => {
    setTestResults(prev => [...prev, { test, result, message, timestamp: new Date().toLocaleTimeString() }]);
  };

  const clearAll = () => {
    setDebugInfo([]);
    setTestResults([]);
  };

  const testConnection = async () => {
    addDebugInfo('🔍 Supabase bağlantısı test ediliyor...');
    
    try {
      const { data, error } = await supabase.from('profiles').select('count').limit(1);
      
      if (error) {
        addDebugInfo(`❌ Bağlantı hatası: ${error.message}`);
        addTestResult('Supabase Bağlantısı', 'error', error.message);
      } else {
        addDebugInfo('✅ Supabase bağlantısı başarılı');
        addTestResult('Supabase Bağlantısı', 'success', 'Bağlantı başarılı');
      }
    } catch (error: any) {
      addDebugInfo(`💥 Bağlantı hatası: ${error.message}`);
      addTestResult('Supabase Bağlantısı', 'error', error.message);
    }
  };

  const testInputValidation = () => {
    addDebugInfo('🔍 Girdi doğrulaması test ediliyor...');
    
    // Email validation
    const isEmailValid = validateEmail(email);
    addDebugInfo(`📧 E-posta doğrulaması: ${isEmailValid ? '✅ Geçerli' : '❌ Geçersiz'}`);
    addTestResult('E-posta Doğrulaması', isEmailValid ? 'success' : 'error', 
      isEmailValid ? 'Geçerli format' : 'Geçersiz format');
    
    // Password validation
    const passwordValidation = validatePassword(password);
    addDebugInfo(`🔐 Şifre doğrulaması: ${passwordValidation.isValid ? '✅ Geçerli' : '❌ Geçersiz'}`);
    addTestResult('Şifre Doğrulaması', passwordValidation.isValid ? 'success' : 'error', 
      passwordValidation.isValid ? 'Geçerli şifre' : passwordValidation.errors[0] || 'Bilinmeyen hata');
    
    if (!passwordValidation.isValid) {
      passwordValidation.errors.forEach(error => {
        addDebugInfo(`   - ${error}`);
      });
    }
    
    return isEmailValid && passwordValidation.isValid;
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
    if (!testInputValidation()) {
      addDebugInfo('❌ Girdi doğrulaması başarısız');
      addTestResult('Kayıt İşlemi', 'error', 'Girdi doğrulaması başarısız');
      setLoading(false);
      return;
    }
    
    try {
      addDebugInfo('📡 Supabase auth.signUp çağrılıyor...');
      
      const { data, error } = await supabase.auth.signUp({
        email: email.toLowerCase().trim(),
        password,
        options: {
          emailRedirectTo: `${window.location.origin}/`,
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
        if (error.message.includes('E-posta onayı gerekli') || error.message.includes('Email not confirmed')) {
          addDebugInfo('✅ Kayıt başarılı - E-posta onayı gerekli');
          addTestResult('Kayıt İşlemi', 'success', 'Kayıt başarılı - E-posta onayı gerekli');
          toast({
            title: 'Kayıt Başarılı!',
            description: 'Hesabınız oluşturuldu. E-posta adresinizi kontrol edin.',
          });
        } else {
          addDebugInfo('❌ Gerçek kayıt hatası');
          addTestResult('Kayıt İşlemi', 'error', error.message);
          
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
        
        addTestResult('Kayıt İşlemi', 'success', 'Kayıt başarılı');
        
        toast({
          title: 'Kayıt Başarılı!',
          description: 'Hesabınız oluşturuldu. E-posta adresinizi kontrol edin.',
        });
      }
    } catch (error: any) {
      addDebugInfo(`💥 Beklenmeyen hata: ${error.message}`);
      addTestResult('Kayıt İşlemi', 'error', `Beklenmeyen hata: ${error.message}`);
      
      toast({
        title: 'Beklenmeyen Hata',
        description: error.message,
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  const clearStorage = () => {
    localStorage.clear();
    sessionStorage.clear();
    addDebugInfo('🧹 Tüm önbellek temizlendi');
    addTestResult('Önbellek Temizleme', 'success', 'Tüm veriler temizlendi');
  };

  const fillTestData = () => {
    setEmail('test@example.com');
    setPassword('Test123');
    setFirstName('Test');
    setLastName('Kullanıcı');
    addDebugInfo('📝 Test verileri dolduruldu');
  };

  return (
    <div className="container mx-auto p-4 max-w-4xl">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HelpCircle className="h-5 w-5" />
            Kayıt Olma Test Sayfası
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          
          {/* Test Butonları */}
          <div className="flex flex-wrap gap-2">
            <Button onClick={testConnection} variant="outline" size="sm">
              <RefreshCw className="h-4 w-4 mr-2" />
              Bağlantıyı Test Et
            </Button>
            <Button onClick={clearStorage} variant="outline" size="sm">
              <Trash2 className="h-4 w-4 mr-2" />
              Önbelleği Temizle
            </Button>
            <Button onClick={fillTestData} variant="outline" size="sm">
              📝 Test Verileri
            </Button>
            <Button onClick={clearAll} variant="outline" size="sm">
              Temizle
            </Button>
          </div>

          <Separator />

          {/* Form */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="firstName">Ad</Label>
              <div className="relative">
                <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="firstName"
                  type="text"
                  placeholder="Adınız"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="lastName">Soyad</Label>
              <div className="relative">
                <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="lastName"
                  type="text"
                  placeholder="Soyadınız"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="email">E-posta</Label>
            <div className="relative">
              <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="email"
                type="email"
                placeholder="ornek@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="password">Şifre</Label>
            <div className="relative">
              <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="password"
                type="password"
                placeholder="En az 6 karakter"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="pl-10"
              />
            </div>
            
            {/* Şifre gereksinimleri */}
            {password.length > 0 && (
              <div className="mt-2 p-3 bg-muted rounded-lg text-sm">
                <div className="font-medium mb-1">🔒 Şifre gereksinimleri:</div>
                <ul className="space-y-1">
                  <li className={password.length >= 6 ? 'text-green-600' : 'text-red-600'}>
                    • En az 6 karakter {password.length >= 6 ? '✅' : '❌'}
                  </li>
                  <li className={/[A-Z]/.test(password) ? 'text-green-600' : 'text-gray-500'}>
                    • Büyük harf {/[A-Z]/.test(password) ? '✅' : '○'}
                  </li>
                  <li className={/[a-z]/.test(password) ? 'text-green-600' : 'text-gray-500'}>
                    • Küçük harf {/[a-z]/.test(password) ? '✅' : '○'}
                  </li>
                  <li className={/[0-9]/.test(password) ? 'text-green-600' : 'text-gray-500'}>
                    • Rakam {/[0-9]/.test(password) ? '✅' : '○'}
                  </li>
                  <li className={/[!@#$%^&*(),.?":{}|<>]/.test(password) ? 'text-green-600' : 'text-gray-500'}>
                    • Özel karakter {/[!@#$%^&*(),.?":{}|<>]/.test(password) ? '✅' : '○'}
                  </li>
                </ul>
                <div className="mt-1 text-blue-600">
                  En az 2 kriteri karşılamanız yeterli!
                </div>
              </div>
            )}
          </div>

          <Button 
            onClick={testSignUp} 
            className="w-full" 
            disabled={loading}
          >
            {loading ? 'Test Ediliyor...' : 'Kayıt İşlemini Test Et'}
          </Button>

          <Separator />

          {/* Test Sonuçları */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">Test Sonuçları</h3>
            <div className="space-y-2">
              {testResults.map((result, index) => (
                <div key={index} className="flex items-center gap-2 p-2 rounded border">
                  {result.result === 'success' && <CheckCircle className="h-4 w-4 text-green-600" />}
                  {result.result === 'error' && <AlertTriangle className="h-4 w-4 text-red-600" />}
                  {result.result === 'warning' && <Info className="h-4 w-4 text-yellow-600" />}
                  <span className="font-medium">{result.test}:</span>
                  <span className="text-sm text-muted-foreground">{result.message}</span>
                  <Badge variant="outline" className="ml-auto text-xs">
                    {result.timestamp}
                  </Badge>
                </div>
              ))}
            </div>
          </div>

          {/* Debug Bilgileri */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">Debug Bilgileri</h3>
            <div className="bg-muted p-4 rounded-lg max-h-60 overflow-y-auto">
              {debugInfo.length === 0 ? (
                <p className="text-muted-foreground">Henüz debug bilgisi yok...</p>
              ) : (
                debugInfo.map((info, index) => (
                  <div key={index} className="text-sm font-mono mb-1">
                    {info}
                  </div>
                ))
              )}
            </div>
          </div>

        </CardContent>
      </Card>
    </div>
  );
}; 