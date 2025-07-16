import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

export const AuthDebug = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [debugInfo, setDebugInfo] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const addDebugInfo = (info: string) => {
    setDebugInfo(prev => [...prev, `${new Date().toLocaleTimeString()}: ${info}`]);
  };

  const testConnection = async () => {
    setLoading(true);
    addDebugInfo('🔍 Supabase bağlantısı test ediliyor...');
    
    try {
      const { data, error } = await supabase.from('profiles').select('count').limit(1);
      
      if (error) {
        addDebugInfo(`❌ Bağlantı hatası: ${error.message}`);
        toast({
          title: 'Bağlantı Hatası',
          description: error.message,
          variant: 'destructive'
        });
      } else {
        addDebugInfo('✅ Supabase bağlantısı başarılı');
        toast({
          title: 'Bağlantı Başarılı',
          description: 'Supabase veritabanına bağlantı kuruldu.',
        });
      }
    } catch (error: any) {
      addDebugInfo(`💥 Beklenmeyen hata: ${error.message}`);
      toast({
        title: 'Beklenmeyen Hata',
        description: error.message,
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
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
    addDebugInfo('🔄 Kayıt işlemi başlatılıyor...');
    addDebugInfo(`📧 E-posta: ${email}`);
    addDebugInfo(`🔐 Şifre uzunluğu: ${password.length}`);
    
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
        toast({
          title: 'Kayıt Hatası',
          description: error.message,
          variant: 'destructive'
        });
      } else {
        addDebugInfo('✅ Kayıt başarılı!');
        addDebugInfo(`👤 Kullanıcı ID: ${data.user?.id || 'N/A'}`);
        addDebugInfo(`📧 Doğrulama gerekli: ${data.user?.email_confirmed_at ? 'Hayır' : 'Evet'}`);
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

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>🔧 Kayıt İşlemi Debug</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
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

          <div className="flex gap-2">
            <Button onClick={testConnection} disabled={loading}>
              🔍 Bağlantı Testi
            </Button>
            <Button onClick={testSignUp} disabled={loading}>
              📝 Kayıt Testi
            </Button>
            <Button onClick={clearDebug} variant="outline">
              🗑️ Temizle
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>📋 Debug Bilgileri</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="bg-gray-100 p-4 rounded-lg max-h-96 overflow-y-auto">
            {debugInfo.length === 0 ? (
              <p className="text-gray-500">Henüz debug bilgisi yok. Test işlemlerini başlatın.</p>
            ) : (
              <div className="space-y-1">
                {debugInfo.map((info, index) => (
                  <div key={index} className="text-sm font-mono">
                    {info}
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}; 