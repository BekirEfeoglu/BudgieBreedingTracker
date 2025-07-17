import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { AlertTriangle, CheckCircle, Info, RefreshCw, Trash2 } from 'lucide-react';
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
    const canSignUp = rateLimitCheck('signup', 3, 60 * 60 * 1000);
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
    
    // Input validation
    if (!validateInputs()) {
      addDebugInfo('❌ Girdi doğrulaması başarısız');
      setLoading(false);
      return;
    }
    
    try {
      const { data, error } = await supabase.auth.signUp({
        email: email.toLowerCase().trim(),
        password,
        options: {
          emailRedirectTo: `${window.location.origin}/`,
          data: {
            first_name: firstName?.trim() || '',
            last_name: lastName?.trim() || '',
          },
        },
      });

      if (error) {
        addDebugInfo(`❌ Kayıt hatası: ${error.message}`);
        addDebugInfo(`📋 Hata kodu: ${error.status || 'N/A'}`);
        addDebugInfo(`🔍 Hata tipi: ${error.name || 'N/A'}`);
        
        // Detaylı hata analizi
        const errorMsg = error.message || '';
        const errorStatus = error.status || 0;
        
        if (errorMsg.includes('already registered') || errorMsg.includes('already exists')) {
          addDebugInfo('💡 Çözüm: Bu e-posta zaten kayıtlı, giriş yapmayı deneyin');
        } else if (errorMsg.includes('weak password')) {
          addDebugInfo('💡 Çözüm: Daha güçlü bir şifre seçin (8+ karakter, büyük/küçük harf, rakam)');
        } else if (errorMsg.includes('network') || errorMsg.includes('fetch')) {
          addDebugInfo('💡 Çözüm: İnternet bağlantınızı kontrol edin');
        } else if (errorStatus === 429) {
          addDebugInfo('💡 Çözüm: Çok fazla deneme, 1 saat bekleyin');
        }
        
        toast({
          title: 'Kayıt Hatası',
          description: error.message,
          variant: 'destructive'
        });
      } else {
        addDebugInfo('✅ Kayıt başarılı!');
        addDebugInfo(`👤 Kullanıcı ID: ${data.user?.id || 'N/A'}`);
        addDebugInfo(`📧 Doğrulama gerekli: ${data.user?.email_confirmed_at ? 'Hayır' : 'Evet'}`);
        addDebugInfo(`🔑 Oturum oluşturuldu: ${data.session ? 'Evet' : 'Hayır'}`);
        
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
            🔧 Kayıt İşlemi Debug
            <Badge variant={connectionStatus === 'connected' ? 'default' : connectionStatus === 'error' ? 'destructive' : 'secondary'}>
              {connectionStatus === 'connected' ? 'Bağlı' : connectionStatus === 'error' ? 'Hata' : 'Kontrol ediliyor'}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Button onClick={testConnection} variant="outline" size="sm">
              <RefreshCw className="w-4 h-4 mr-2" />
              Bağlantıyı Test Et
            </Button>
            <Button onClick={clearRateLimits} variant="outline" size="sm">
              <Trash2 className="w-4 h-4 mr-2" />
              Rate Limit Temizle
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
                placeholder="En az 8 karakter"
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
              <strong>Şifre Gereksinimleri:</strong>
              <ul className="text-sm text-muted-foreground ml-4 mt-1">
                <li>• En az 8 karakter</li>
                <li>• En az bir büyük harf</li>
                <li>• En az bir küçük harf</li>
                <li>• En az bir rakam</li>
              </ul>
            </div>
          </div>
          
          <div className="flex items-start gap-2">
            <CheckCircle className="w-4 h-4 text-green-500 mt-0.5" />
            <div>
              <strong>Başarılı Kayıt:</strong>
              <p className="text-sm text-muted-foreground mt-1">
                E-posta doğrulama bağlantısı gönderilir. E-posta kutunuzu kontrol edin.
              </p>
            </div>
          </div>
          
          <div className="flex items-start gap-2">
            <Info className="w-4 h-4 text-blue-500 mt-0.5" />
            <div>
              <strong>Rate Limiting:</strong>
              <p className="text-sm text-muted-foreground mt-1">
                Saatte en fazla 3 kayıt denemesi yapabilirsiniz. Limit aşılırsa "Rate Limit Temizle" butonunu kullanın.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}; 