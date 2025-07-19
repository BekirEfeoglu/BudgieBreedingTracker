import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { AlertTriangle, CheckCircle, Info, RefreshCw, Wifi, WifiOff, Globe, Shield } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { useLocalAuth } from '@/hooks/useLocalAuth';

const EmergencyTestPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [loading, setLoading] = useState(false);
  const [testResults, setTestResults] = useState<string[]>([]);
  const [useLocalAuthMode, setUseLocalAuthMode] = useState(false);

  const { signUp, signIn, user, signOut } = useLocalAuth();

  const addTestResult = (message: string, type: 'success' | 'error' | 'info' | 'warning' = 'info') => {
    const timestamp = new Date().toLocaleTimeString();
    const icon = type === 'success' ? '✅' : type === 'error' ? '❌' : type === 'warning' ? '⚠️' : 'ℹ️';
    setTestResults(prev => [`[${timestamp}] ${icon} ${message}`, ...prev.slice(0, 19)]);
  };

  const testSupabaseConnection = async () => {
    setLoading(true);
    addTestResult('🔍 Supabase bağlantısı test ediliyor...', 'info');
    
    try {
      const startTime = Date.now();
      const response = await fetch('https://jxbfdgyusoehqybxdnii.supabase.co/auth/v1/health', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        }
      });
      const endTime = Date.now();
      
      if (response.ok) {
        addTestResult(`✅ Supabase bağlantısı başarılı (${endTime - startTime}ms)`, 'success');
      } else {
        addTestResult(`❌ Supabase bağlantısı başarısız: ${response.status}`, 'error');
      }
    } catch (error: any) {
      addTestResult(`💥 Supabase bağlantı hatası: ${error.message}`, 'error');
    } finally {
      setLoading(false);
    }
  };

  const testLocalAuth = async () => {
    if (!email || !password) {
      toast({
        title: 'Eksik Bilgi',
        description: 'E-posta ve şifre gerekli.',
        variant: 'destructive'
      });
      return;
    }

    setLoading(true);
    addTestResult('🔄 Local auth test başlatılıyor...', 'info');
    addTestResult(`📧 E-posta: ${email}`, 'info');
    addTestResult(`🔐 Şifre uzunluğu: ${password.length}`, 'info');
    
    try {
      const { error } = await signUp(email, password, firstName, lastName);
      
      if (error) {
        addTestResult(`❌ Local auth hatası: ${error.message}`, 'error');
        toast({
          title: 'Local Auth Hatası',
          description: error.message,
          variant: 'destructive'
        });
      } else {
        addTestResult('✅ Local auth başarılı!', 'success');
        addTestResult(`👤 Kullanıcı ID: ${user?.id}`, 'success');
        addTestResult(`📧 E-posta: ${user?.email}`, 'success');
        toast({
          title: 'Local Auth Başarılı!',
          description: 'Hesabınız oluşturuldu ve giriş yapıldı.',
        });
      }
    } catch (error: any) {
      addTestResult(`💥 Beklenmeyen hata: ${error.message}`, 'error');
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
    
    addTestResult('🧹 Tüm veriler temizlendi', 'success');
    toast({
      title: 'Veriler Temizlendi',
      description: 'Tüm veriler temizlendi. Artık yeni test yapabilirsiniz.',
    });
  };

  const generateTestData = () => {
    const testEmail = `test${Date.now()}@gmail.com`;
    const testPassword = 'Test123456';
    const testFirstName = 'Test';
    const testLastName = 'Kullanıcı';
    
    setEmail(testEmail);
    setPassword(testPassword);
    setFirstName(testFirstName);
    setLastName(testLastName);
    
    addTestResult(`📧 Test e-postası: ${testEmail}`, 'info');
    addTestResult(`🔐 Test şifresi: ${testPassword}`, 'info');
  };

  const checkNetworkStatus = async () => {
    addTestResult('🌐 Network durumu kontrol ediliyor...', 'info');
    
    try {
      const ipResponse = await fetch('https://api.ipify.org?format=json');
      const ipData = await ipResponse.json();
      
      addTestResult(`🌐 IP Adresi: ${ipData.ip}`, 'info');
      addTestResult(`📱 Platform: ${navigator.platform}`, 'info');
      addTestResult(`🌍 Dil: ${navigator.language}`, 'info');
      addTestResult(`📶 Online: ${navigator.onLine ? 'Evet' : 'Hayır'}`, navigator.onLine ? 'success' : 'error');
    } catch (error) {
      addTestResult('❌ Network bilgileri alınamadı', 'error');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-50 via-orange-100 to-yellow-100 p-4">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertTriangle className="w-6 h-6 text-red-600" />
              Acil Durum Test Merkezi
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="flex items-center gap-2 p-3 bg-red-50 rounded-lg">
                <WifiOff className="w-5 h-5 text-red-600" />
                <div>
                  <div className="font-semibold text-sm">Supabase Sorunu</div>
                  <div className="text-xs text-gray-600">504 Gateway Timeout</div>
                </div>
              </div>
              <div className="flex items-center gap-2 p-3 bg-amber-50 rounded-lg">
                <AlertTriangle className="w-5 h-5 text-amber-600" />
                <div>
                  <div className="font-semibold text-sm">Rate Limiting</div>
                  <div className="text-xs text-gray-600">429 Too Many Requests</div>
                </div>
              </div>
              <div className="flex items-center gap-2 p-3 bg-green-50 rounded-lg">
                <CheckCircle className="w-5 h-5 text-green-600" />
                <div>
                  <div className="font-semibold text-sm">Local Auth</div>
                  <div className="text-xs text-gray-600">Geçici çözüm</div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Test Seçenekleri */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">🧪 Test Seçenekleri</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-4 border rounded-lg">
                <h3 className="font-semibold mb-2 flex items-center gap-2">
                  <Globe className="w-4 h-4" />
                  Supabase Bağlantı Testi
                </h3>
                <p className="text-sm text-gray-600 mb-3">
                  Supabase sunucularının durumunu kontrol edin.
                </p>
                <Button onClick={testSupabaseConnection} disabled={loading} className="w-full">
                  {loading ? 'Test Ediliyor...' : 'Supabase Test Et'}
                </Button>
              </div>

              <div className="p-4 border rounded-lg">
                <h3 className="font-semibold mb-2 flex items-center gap-2">
                  <Shield className="w-4 h-4" />
                  Local Auth Testi
                </h3>
                <p className="text-sm text-gray-600 mb-3">
                  Geçici local authentication ile test edin.
                </p>
                <Button 
                  onClick={() => setUseLocalAuthMode(!useLocalAuthMode)} 
                  variant={useLocalAuthMode ? "default" : "outline"}
                  className="w-full"
                >
                  {useLocalAuthMode ? 'Local Auth Aktif' : 'Local Auth Aç'}
                </Button>
              </div>
            </div>

            <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <h3 className="font-semibold mb-2 text-blue-800">💡 Öneri</h3>
              <p className="text-sm text-blue-700">
                Supabase sorunları devam ediyorsa, geçici olarak Local Auth kullanarak uygulamayı test edebilirsiniz. 
                Bu sadece geliştirme amaçlıdır ve veriler local storage'da saklanır.
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Test Formu */}
        {useLocalAuthMode && (
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">🔐 Local Auth Test Formu</CardTitle>
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
                <Button onClick={testLocalAuth} disabled={loading}>
                  {loading ? 'Test Ediliyor...' : 'Local Auth Test Et'}
                </Button>
                <Button variant="outline" onClick={generateTestData}>
                  <RefreshCw className="w-4 h-4 mr-2" />
                  Test Verisi Oluştur
                </Button>
                <Button variant="outline" onClick={clearAllData}>
                  <RefreshCw className="w-4 h-4 mr-2" />
                  Verileri Temizle
                </Button>
                <Button variant="outline" onClick={checkNetworkStatus}>
                  <Globe className="w-4 h-4 mr-2" />
                  Network Kontrol
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Test Sonuçları */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center justify-between">
              <span>📊 Test Sonuçları</span>
              <Badge variant="outline">{testResults.length} sonuç</Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="bg-gray-50 rounded-lg p-4 h-64 overflow-y-auto font-mono text-xs">
              {testResults.length === 0 ? (
                <div className="text-gray-500 text-center py-8">
                  Henüz test sonucu yok. Test başlatın...
                </div>
              ) : (
                testResults.map((result, index) => (
                  <div key={index} className="mb-1">
                    {result}
                  </div>
                ))
              )}
            </div>
          </CardContent>
        </Card>

        {/* Mevcut Kullanıcı */}
        {user && (
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">👤 Mevcut Kullanıcı</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span>ID:</span>
                  <Badge variant="outline">{user.id}</Badge>
                </div>
                <div className="flex justify-between">
                  <span>E-posta:</span>
                  <Badge variant="outline">{user.email}</Badge>
                </div>
                <div className="flex justify-between">
                  <span>Ad:</span>
                  <Badge variant="outline">{user.firstName}</Badge>
                </div>
                <div className="flex justify-between">
                  <span>Kayıt Tarihi:</span>
                  <Badge variant="outline">{new Date(user.createdAt).toLocaleString()}</Badge>
                </div>
                <Button onClick={signOut} variant="outline" className="w-full mt-4">
                  Çıkış Yap
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
};

export default EmergencyTestPage; 