import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Lock, Eye, EyeOff, Shield } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { useSecureAuth } from '@/hooks/useSecureAuth';
import { validatePassword } from '@/utils/inputSanitization';

const PasswordChange = () => {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [passwordStrength, setPasswordStrength] = useState({ isValid: false, errors: [] as string[] });

  const { updatePassword } = useSecureAuth();

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
      await updatePassword(newPassword, currentPassword);

      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      setPasswordStrength({ isValid: false, errors: [] });
    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Bir hata oluştu. Lütfen tekrar deneyin.',
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
    <Card className="budgie-card">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Shield className="w-5 h-5" />
          Güvenli Şifre Değiştir
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="space-y-3">
          <Label htmlFor="currentPassword" className="text-sm font-medium">Mevcut Şifre</Label>
          <div className="relative">
            <Input
              id="currentPassword"
              type={showCurrentPassword ? 'text' : 'password'}
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              placeholder="Mevcut şifrenizi girin"
              className="pr-12 min-h-[48px] text-base"
            />
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8 p-0 hover:bg-transparent"
              onClick={() => setShowCurrentPassword(!showCurrentPassword)}
            >
              {showCurrentPassword ? (
                <EyeOff className="h-4 w-4" />
              ) : (
                <Eye className="h-4 w-4" />
              )}
            </Button>
          </div>
        </div>

        <div className="space-y-3">
          <Label htmlFor="newPassword" className="text-sm font-medium">Yeni Şifre</Label>
          <div className="relative">
            <Input
              id="newPassword"
              type={showNewPassword ? 'text' : 'password'}
              value={newPassword}
              onChange={(e) => handleNewPasswordChange(e.target.value)}
              placeholder="Yeni şifrenizi girin"
              className="pr-12 min-h-[48px] text-base"
            />
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8 p-0 hover:bg-transparent"
              onClick={() => setShowNewPassword(!showNewPassword)}
            >
              {showNewPassword ? (
                <EyeOff className="h-4 w-4" />
              ) : (
                <Eye className="h-4 w-4" />
              )}
            </Button>
          </div>
        </div>

        <div className="space-y-3">
          <Label htmlFor="confirmPassword" className="text-sm font-medium">Yeni Şifre (Tekrar)</Label>
          <div className="relative">
            <Input
              id="confirmPassword"
              type={showConfirmPassword ? 'text' : 'password'}
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Yeni şifrenizi tekrar girin"
              className="pr-12 min-h-[48px] text-base"
            />
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8 p-0 hover:bg-transparent"
              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
            >
              {showConfirmPassword ? (
                <EyeOff className="h-4 w-4" />
              ) : (
                <Eye className="h-4 w-4" />
              )}
            </Button>
          </div>
        </div>

        <Button 
          onClick={handlePasswordChange} 
          className="w-full budgie-button min-h-[48px] text-base font-medium" 
          disabled={loading || !currentPassword || !newPassword || !confirmPassword}
        >
          <Lock className="w-4 h-4 mr-2" />
          {loading ? 'Güncelleniyor...' : 'Şifreyi Güncelle'}
        </Button>

        {/* Password Strength Indicator */}
        {newPassword && (
          <div className="space-y-2">
            <div className="text-sm font-medium">Şifre Güvenlik Seviyesi</div>
            <div className="space-y-1">
              <div className={`h-2 rounded-full transition-colors ${
                passwordStrength.isValid ? 'bg-green-500' : 'bg-red-500'
              }`}></div>
              {!passwordStrength.isValid && passwordStrength.errors.length > 0 && (
                <div className="text-xs text-destructive space-y-1">
                  {passwordStrength.errors.map((error, index) => (
                    <div key={index}>• {error}</div>
                  ))}
                </div>
              )}
              {passwordStrength.isValid && (
                <div className="text-xs text-green-600">✅ Güvenli şifre</div>
              )}
            </div>
          </div>
        )}

        <div className="text-sm text-muted-foreground bg-muted/30 p-3 rounded-lg space-y-2">
          <div className="font-medium">🔒 Güvenli şifre gereksinimleri:</div>
          <ul className="text-xs space-y-1">
            <li>• En az 8 karakter</li>
            <li>• En az 1 büyük harf (A-Z)</li>
            <li>• En az 1 küçük harf (a-z)</li>
            <li>• En az 1 rakam (0-9)</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
};

export default PasswordChange;
