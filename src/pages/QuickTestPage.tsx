import React, { useState } from 'react';
import { AdvancedAuthDebug } from '@/components/auth/AdvancedAuthDebug';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { AlertTriangle, CheckCircle, Info, Shield, Globe, Wifi } from 'lucide-react';

const QuickTestPage = () => {
  const [showAdvancedDebug, setShowAdvancedDebug] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-100 to-purple-100 p-4">
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield className="w-6 h-6 text-blue-600" />
              BudgieBreedingTracker - Kayıt Sorunu Çözüm Merkezi
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="flex items-center gap-2 p-3 bg-blue-50 rounded-lg">
                <Globe className="w-5 h-5 text-blue-600" />
                <div>
                  <div className="font-semibold text-sm">Rate Limiting</div>
                  <div className="text-xs text-gray-600">IP bazlı kısıtlama</div>
                </div>
              </div>
              <div className="flex items-center gap-2 p-3 bg-amber-50 rounded-lg">
                <AlertTriangle className="w-5 h-5 text-amber-600" />
                <div>
                  <div className="font-semibold text-sm">E-posta Doğrulama</div>
                  <div className="text-xs text-gray-600">Zorunlu onay</div>
                </div>
              </div>
              <div className="flex items-center gap-2 p-3 bg-green-50 rounded-lg">
                <CheckCircle className="w-5 h-5 text-green-600" />
                <div>
                  <div className="font-semibold text-sm">Çözüm Araçları</div>
                  <div className="text-xs text-gray-600">Debug & Test</div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Hızlı Çözümler */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">🚀 Hızlı Çözümler</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-4 border rounded-lg">
                <h3 className="font-semibold mb-2 flex items-center gap-2">
                  <Wifi className="w-4 h-4" />
                  VPN / Mobil Veri
                </h3>
                <p className="text-sm text-gray-600 mb-3">
                  IP adresiniz rate limit'e takılmış. Farklı IP ile deneyin.
                </p>
                <div className="space-y-2 text-xs">
                  <div className="flex items-center gap-2">
                    <Badge variant="outline">1</Badge>
                    <span>VPN indirin (ExpressVPN, NordVPN)</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="outline">2</Badge>
                    <span>Mobil veri kullanın</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="outline">3</Badge>
                    <span>Farklı WiFi kullanın</span>
                  </div>
                </div>
              </div>

              <div className="p-4 border rounded-lg">
                <h3 className="font-semibold mb-2 flex items-center gap-2">
                  <Globe className="w-4 h-4" />
                  Supabase Dashboard
                </h3>
                <p className="text-sm text-gray-600 mb-3">
                  Rate limiting'i devre dışı bırakın.
                </p>
                <div className="space-y-2 text-xs">
                  <div className="flex items-center gap-2">
                    <Badge variant="outline">1</Badge>
                    <span>Supabase Dashboard'a gidin</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="outline">2</Badge>
                    <span>Authentication → Settings</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="outline">3</Badge>
                    <span>Rate limiting değerlerini 999999999 yapın</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg">
              <h3 className="font-semibold mb-2 text-amber-800">⚠️ Önemli Not</h3>
              <p className="text-sm text-amber-700">
                Bu sorun Supabase sunucu tarafında oluşuyor. Client-side kodla çözülemez. 
                VPN kullanmak veya Supabase Dashboard'da ayarları değiştirmek gerekli.
              </p>
            </div>
          </CardContent>
        </Card>

        {/* SQL Komutları */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">🔧 Supabase SQL Komutları</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm overflow-x-auto">
              <div className="mb-2 text-yellow-400">-- Supabase Dashboard SQL Editor'da çalıştırın</div>
              <div className="mb-1">UPDATE auth.config SET</div>
              <div className="ml-4 mb-1">rate_limit_email_sent = 999999999,</div>
              <div className="ml-4 mb-1">rate_limit_sms_sent = 999999999,</div>
              <div className="ml-4 mb-1">rate_limit_verify = 999999999,</div>
              <div className="ml-4 mb-1">rate_limit_email_change = 999999999,</div>
              <div className="ml-4 mb-1">rate_limit_phone_change = 999999999,</div>
              <div className="ml-4 mb-1">rate_limit_signup = 999999999,</div>
              <div className="ml-4 mb-1">rate_limit_signin = 999999999,</div>
              <div className="ml-4 mb-3">rate_limit_reset = 999999999;</div>
              <div className="mb-1">UPDATE auth.config SET enable_email_confirmations = false;</div>
            </div>
          </CardContent>
        </Card>

        {/* Gelişmiş Debug */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center justify-between">
              <span>🔍 Gelişmiş Debug Paneli</span>
              <Button 
                variant="outline" 
                onClick={() => setShowAdvancedDebug(!showAdvancedDebug)}
              >
                {showAdvancedDebug ? 'Gizle' : 'Göster'}
              </Button>
            </CardTitle>
          </CardHeader>
          <CardContent>
            {showAdvancedDebug ? (
              <AdvancedAuthDebug />
            ) : (
              <div className="text-center py-8 text-gray-500">
                Gelişmiş debug araçlarını görmek için "Göster" butonuna tıklayın.
              </div>
            )}
          </CardContent>
        </Card>

        {/* Alternatif Çözümler */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">🔄 Alternatif Çözümler</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-4 border rounded-lg">
                <h3 className="font-semibold mb-2">📧 E-posta Alias'ları</h3>
                <ul className="text-sm text-gray-600 space-y-1">
                  <li>• Gmail: bekirefe016+test@gmail.com</li>
                  <li>• Outlook: bekirefe016+test@outlook.com</li>
                  <li>• Yahoo: bekirefe016+test@yahoo.com</li>
                </ul>
              </div>
              <div className="p-4 border rounded-lg">
                <h3 className="font-semibold mb-2">⏰ Bekleme Süreleri</h3>
                <ul className="text-sm text-gray-600 space-y-1">
                  <li>• 15 dakika: Giriş denemeleri</li>
                  <li>• 1 saat: Kayıt denemeleri</li>
                  <li>• 24 saat: Tam sıfırlama</li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default QuickTestPage; 