import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Lock, Eye, EyeOff, Shield } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { useAuth } from '@/hooks/useAuth';
import { validatePassword } from '@/utils/inputSanitization';

interface PasswordChangeProps {
  onClose?: () => void;
}

const PasswordChange = ({ onClose }: PasswordChangeProps) => {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [passwordStrength, setPasswordStrength] = useState({ isValid: false, errors: [] as string[] });

  const { updatePassword } = useAuth();

  const handlePasswordChange = async () => {
    // Password confirmation check
    if (newPassword !== confirmPassword) {
      toast({
        title: 'Hata',
        description: 'Yeni şifreler eşleşmiyor.',
        variant: 'destructive',
      });
      return;
    }

    // Password strength validation
    const validation = validatePassword(newPassword);
    if (!validation.isValid) {
      toast({
        title: 'Şifre Güvenlik Hatası',
        description: validation.errors[0],
        variant: 'destructive',
      });
      return;
    }

    setLoading(true);
    try {
      console.log('🔄 Şifre güncelleniyor...');
      
      await updatePassword(newPassword, currentPassword);

      console.log('✅ Şifre başarıyla güncellendi');

      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      setPasswordStrength({ isValid: false, errors: [] });
      
      toast({
        title: 'Başarılı!',
        description: 'Şifreniz başarıyla güncellendi.',
      });
      
      // Modal'ı kapat
      if (onClose) {
        onClose();
      }
    } catch (error) {
      console.error('❌ Şifre güncelleme hatası:', error);
      toast({
        title: 'Güncelleme Hatası',
        description: error instanceof Error ? error.message : 'Şifre güncellenirken bir hata oluştu.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  // Real-time password strength validation
  const handleNewPasswordChange = (value: string) => {
    setNewPassword(value);
    const validation = validatePassword(value);
    setPasswordStrength(validation);
  };

  return (
    <div className="space-y-8">
      {/* Başlık */}
      <div className="text-center">
        <div className="w-20 h-20 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center mx-auto mb-6 shadow-lg animate-pulse">
          <Shield className="w-10 h-10 text-white" />
        </div>
        <h3 className="text-xl font-bold text-gray-800 mb-3 bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
          Güvenli Şifre Değiştir
        </h3>
        <p className="text-sm text-gray-600 leading-relaxed">
          Hesabınızın güvenliği için güçlü bir şifre seçin
        </p>
      </div>
        <div className="space-y-3">
          <Label htmlFor="currentPassword" className="text-sm font-semibold text-gray-700 flex items-center gap-2">
            <Lock className="w-4 h-4 text-blue-600" />
            Mevcut Şifre
          </Label>
          <div className="relative group">
            <Input
              id="currentPassword"
              type={showCurrentPassword ? 'text' : 'password'}
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              placeholder="Mevcut şifrenizi girin"
              className="pr-12 h-12 text-base border-2 border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all duration-300 group-hover:border-gray-300"
            />
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8 p-0 hover:bg-blue-50 rounded-full transition-colors"
              onClick={() => setShowCurrentPassword(!showCurrentPassword)}
            >
              {showCurrentPassword ? (
                <EyeOff className="h-4 w-4 text-gray-500" />
              ) : (
                <Eye className="h-4 w-4 text-gray-500" />
              )}
            </Button>
          </div>
        </div>

        <div className="space-y-3">
          <Label htmlFor="newPassword" className="text-sm font-semibold text-gray-700 flex items-center gap-2">
            <Shield className="w-4 h-4 text-green-600" />
            Yeni Şifre
          </Label>
          <div className="relative group">
            <Input
              id="newPassword"
              type={showNewPassword ? 'text' : 'password'}
              value={newPassword}
              onChange={(e) => handleNewPasswordChange(e.target.value)}
              placeholder="Yeni şifrenizi girin"
              className="pr-12 h-12 text-base border-2 border-gray-200 focus:border-green-500 focus:ring-2 focus:ring-green-200 transition-all duration-300 group-hover:border-gray-300"
            />
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8 p-0 hover:bg-green-50 rounded-full transition-colors"
              onClick={() => setShowNewPassword(!showNewPassword)}
            >
              {showNewPassword ? (
                <EyeOff className="h-4 w-4 text-gray-500" />
              ) : (
                <Eye className="h-4 w-4 text-gray-500" />
              )}
            </Button>
          </div>
        </div>

        <div className="space-y-3">
          <Label htmlFor="confirmPassword" className="text-sm font-semibold text-gray-700 flex items-center gap-2">
            <Shield className="w-4 h-4 text-purple-600" />
            Yeni Şifre (Tekrar)
          </Label>
          <div className="relative group">
            <Input
              id="confirmPassword"
              type={showConfirmPassword ? 'text' : 'password'}
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Yeni şifrenizi tekrar girin"
              className="pr-12 h-12 text-base border-2 border-gray-200 focus:border-purple-500 focus:ring-2 focus:ring-purple-200 transition-all duration-300 group-hover:border-gray-300"
            />
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8 p-0 hover:bg-purple-50 rounded-full transition-colors"
              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
            >
              {showConfirmPassword ? (
                <EyeOff className="h-4 w-4 text-gray-500" />
              ) : (
                <Eye className="h-4 w-4 text-gray-500" />
              )}
            </Button>
          </div>
        </div>

        <Button 
          onClick={handlePasswordChange} 
          className="w-full h-12 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white shadow-lg hover:shadow-xl transition-all duration-300 font-semibold" 
          disabled={loading || !currentPassword || !newPassword || !confirmPassword}
        >
          <Lock className="w-5 h-5 mr-2" />
          {loading ? 'Güncelleniyor...' : 'Şifreyi Güncelle'}
        </Button>

        {/* Password Strength Indicator */}
        {newPassword && (
          <div className="space-y-3 p-4 bg-gradient-to-r from-gray-50 to-blue-50 rounded-xl border border-blue-100">
            <div className="flex items-center gap-2">
              <div className={`w-3 h-3 rounded-full ${passwordStrength.isValid ? 'bg-green-500' : 'bg-red-500'} animate-pulse`}></div>
              <div className="text-sm font-semibold text-gray-700">Şifre Güvenlik Seviyesi</div>
            </div>
          <div className="space-y-2">
              <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                <div 
                  className={`h-2 rounded-full transition-all duration-500 ${
                    passwordStrength.isValid 
                      ? 'bg-gradient-to-r from-green-400 to-green-600' 
                      : 'bg-gradient-to-r from-red-400 to-red-600'
                  }`}
                  style={{ 
                    width: passwordStrength.isValid ? '100%' : `${Math.min(50, newPassword.length * 10)}%` 
                  }}
                ></div>
              </div>
              {!passwordStrength.isValid && passwordStrength.errors.length > 0 && (
                <div className="text-xs text-red-600 space-y-1 bg-red-50 p-2 rounded-lg border border-red-100">
                  {passwordStrength.errors.map((error, index) => (
                    <div key={index} className="flex items-center gap-1">
                      <div className="w-1 h-1 bg-red-500 rounded-full"></div>
                      {error}
                    </div>
                  ))}
                </div>
              )}
              {passwordStrength.isValid && (
                <div className="text-xs text-green-700 bg-green-50 p-2 rounded-lg border border-green-100 flex items-center gap-2">
                  <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                  ✅ Güvenli şifre
                </div>
              )}
            </div>
          </div>
        )}

        <div className="text-sm text-gray-600 bg-gradient-to-br from-blue-50 to-indigo-50 p-6 rounded-xl space-y-3 border border-blue-200 shadow-sm">
          <div className="flex items-center gap-2 font-semibold text-blue-800">
            <div className="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center">
              <Lock className="w-3 h-3 text-blue-600" />
            </div>
            Güvenli şifre gereksinimleri
          </div>
          <ul className="text-xs space-y-2 text-blue-700">
            <li className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
              En az 8 karakter
            </li>
            <li className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
              En az 1 büyük harf (A-Z)
            </li>
            <li className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
              En az 1 küçük harf (a-z)
            </li>
            <li className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
              En az 1 rakam (0-9)
            </li>
          </ul>
        </div>
      </div>
  );
};

export default PasswordChange;
