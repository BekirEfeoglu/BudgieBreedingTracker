
import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useAuth } from '@/hooks/useAuth';
import { User, ArrowLeft, LogOut, AlertTriangle } from 'lucide-react';
import { toast } from '@/components/ui/use-toast';
import { useLanguage } from '@/contexts/LanguageContext';
import { ConfirmationDialog } from '@/components/ui/confirmation-dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import AvatarUpload from '@/components/profile/AvatarUpload';
import ProfileForm from '@/components/profile/ProfileForm';
import PasswordChange from '@/components/profile/PasswordChange';
import ProfileInfoNote from '@/components/profile/ProfileInfoNote';
import { useAccountDeletion } from '@/hooks/useAccountDeletion';

interface ProfileSettingsProps {
  onBack?: () => void;
}

const ProfileSettings = ({ onBack }: ProfileSettingsProps) => {
  const { profile, signOut } = useAuth();
  const { t } = useLanguage();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteAccount, setShowDeleteAccount] = useState(false);
  const { deleteAccount, isDeleting } = useAccountDeletion();

  const getInitials = () => {
    const first = profile?.first_name || '';
    const last = profile?.last_name || '';
    return `${first.charAt(0)}${last.charAt(0)}`.toUpperCase();
  };

  const displayName = () => {
    const first = profile?.first_name || '';
    const last = profile?.last_name || '';
    return `${first} ${last}`.trim() || 'User';
  };

  const handleSignOut = async () => {
    try {
      await signOut();
      toast({
        title: 'Başarıyla Çıkış Yapıldı',
        description: 'Güvenli bir şekilde çıkış yaptınız.',
      });
    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Çıkış yapılırken bir hata oluştu.',
        variant: 'destructive',
      });
    }
  };

  const handleDeleteAccount = async () => {
    setShowDeleteAccount(false);
    await deleteAccount();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-budgie-cream to-budgie-warm">
      <div className="mobile-container py-6 max-w-2xl px-4 sm:px-6">
        {/* Modern Header */}
        <div className="flex items-center gap-4 mb-8">
          {onBack && (
            <Button
              variant="ghost"
              size="sm"
              onClick={onBack}
              className="p-3 hover:bg-white/20 rounded-full backdrop-blur-sm touch-target"
              aria-label="Geri"
            >
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 budgie-gradient rounded-2xl flex items-center justify-center text-2xl shadow-lg flex-shrink-0">
              👤
            </div>
            <div className="min-w-0 flex-1">
              <h1 className="mobile-title sm:text-3xl font-bold text-foreground">Profil</h1>
              <p className="text-muted-foreground mobile-text-sm">Hesap bilgilerinizi yönetin</p>
            </div>
          </div>
        </div>

        <div className="space-y-8">
          {/* Profil Bilgileri */}
          <Card className="enhanced-card shadow-lg backdrop-blur-sm bg-white/95">
            <CardHeader className="pb-6">
              <CardTitle className="flex items-center gap-3 mobile-title">
                <User className="w-6 h-6 text-primary" />
                Kişisel Bilgiler
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-8">
              <AvatarUpload
                avatarUrl={profile?.avatar_url}
                initials={getInitials()}
                displayName={displayName()}
              />

              <ProfileForm
                initialFirstName={profile?.first_name || ''}
                initialLastName={profile?.last_name || ''}
              />
            </CardContent>
          </Card>

          {/* Şifre Değiştir */}
          <PasswordChange />

          <ProfileInfoNote />

          {/* Çıkış Yap ve Hesap Sil */}
          <div className="space-y-4">
            <Card className="enhanced-card shadow-lg backdrop-blur-sm bg-white/95 border-red-200">
              <CardContent className="pt-6">
                <div className="text-center space-y-4">
                  <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto">
                    <LogOut className="w-8 h-8 text-red-600" />
                  </div>
                  <div>
                    <h3 className="mobile-title text-foreground mb-2">
                      Hesaptan Çıkış
                    </h3>
                    <p className="mobile-text-sm text-muted-foreground mb-4">
                      Bu işlem sizi güvenli bir şekilde çıkış yapacaktır
                    </p>
                  </div>
                  <Button 
                    onClick={() => setShowLogoutConfirm(true)}
                    variant="destructive" 
                    className="w-full touch-target mobile-body font-medium"
                  >
                    <LogOut className="w-5 h-5 mr-2" />
                    Çıkış Yap
                  </Button>
                </div>
              </CardContent>
            </Card>

            <Card className="enhanced-card shadow-lg backdrop-blur-sm bg-white/95 border-red-200">
              <CardContent className="pt-6">
                <div className="text-center space-y-4">
                  <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto">
                    <AlertTriangle className="w-8 h-8 text-red-600" />
                  </div>
                  <div>
                    <h3 className="mobile-title text-foreground mb-2">
                      Hesabı Kalıcı Olarak Sil
                    </h3>
                    <p className="mobile-text-sm text-muted-foreground mb-4">
                      Bu işlem geri alınamaz. Hesabınız ve tüm verileriniz kalıcı olarak silinecektir.
                    </p>
                  </div>
                  <AlertDialog open={showDeleteAccount} onOpenChange={setShowDeleteAccount}>
                    <AlertDialogTrigger asChild>
                      <Button 
                        variant="destructive" 
                        className="w-full touch-target mobile-body font-medium"
                        disabled={isDeleting}
                      >
                        <AlertTriangle className="w-5 h-5 mr-2" />
                        {isDeleting ? 'Siliniyor...' : 'Hesabı Sil'}
                      </Button>
                    </AlertDialogTrigger>
                    <AlertDialogContent className="mobile-modal-content">
                      <AlertDialogHeader className="mobile-modal-header">
                        <AlertDialogTitle>Hesabı Kalıcı Olarak Sil</AlertDialogTitle>
                        <AlertDialogDescription>
                          <div className="space-y-3">
                            <p className="font-semibold text-red-600">⚠️ Bu işlem geri alınamaz!</p>
                            <p>Hesabınızı sildiğinizde:</p>
                            <div className="space-y-1 text-sm">
                              <div>• Tüm kuş kayıtlarınız silinecek</div>
                              <div>• Kuluçka ve yumurta verileriniz silinecek</div>
                              <div>• Yavru kayıtlarınız silinecek</div>
                              <div>• Takvim etkinlikleriniz silinecek</div>
                              <div>• Profil bilgileriniz silinecek</div>
                              <div>• Tüm yedekleme verileriniz silinecek</div>
                            </div>
                            <p className="font-semibold">Bu işlemi onaylıyor musunuz?</p>
                          </div>
                        </AlertDialogDescription>
                      </AlertDialogHeader>
                      <AlertDialogFooter>
                        <AlertDialogCancel disabled={isDeleting}>İptal</AlertDialogCancel>
                        <AlertDialogAction 
                          onClick={handleDeleteAccount}
                          disabled={isDeleting}
                          className="bg-red-600 hover:bg-red-700"
                        >
                          {isDeleting ? 'Siliniyor...' : 'Evet, Hesabımı Sil'}
                        </AlertDialogAction>
                      </AlertDialogFooter>
                    </AlertDialogContent>
                  </AlertDialog>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Logout Confirmation Dialog */}
      <ConfirmationDialog
        isOpen={showLogoutConfirm}
        onClose={() => setShowLogoutConfirm(false)}
        onConfirm={handleSignOut}
        title="Çıkış Yapmak İstediğinizden Emin misiniz?"
        description="Bu işlem sizi güvenli bir şekilde çıkış yapacaktır. Tekrar giriş yapmak için kullanıcı adı ve şifrenizi girmeniz gerekecektir."
        confirmText="Evet, Çıkış Yap"
        cancelText="İptal"
        variant="destructive"
      />
    </div>
  );
};

export default ProfileSettings;
