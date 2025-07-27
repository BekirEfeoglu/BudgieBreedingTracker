import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { AlertTriangle, LogOut, Trash2, User } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useAccountDeletion } from '@/hooks/useAccountDeletion';
import { toast } from '@/components/ui/use-toast';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import ProfileForm from '@/components/profile/ProfileForm';
import AvatarUpload from '@/components/profile/AvatarUpload';

const AccountSettings = () => {
  const { profile, signOut } = useAuth();
  const { deleteAccount, isDeleting } = useAccountDeletion();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteAccount, setShowDeleteAccount] = useState(false);

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
    try {
      await deleteAccount();
    } catch (error) {
      console.error('Hesap silme hatası:', error);
    }
  };

  return (
    <div className="space-y-6">
      {/* Profil Bilgileri */}
      <Card className="budgie-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <User className="w-5 h-5 text-primary" />
            Kişisel Bilgiler
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-8">
          <AvatarUpload
            avatarUrl={profile?.avatar_url || null}
            initials={getInitials()}
            displayName={displayName()}
          />

          <ProfileForm
            initialFirstName={profile?.first_name || ''}
            initialLastName={profile?.last_name || ''}
          />
        </CardContent>
      </Card>

      {/* Güvenlik ve Çıkış İşlemleri */}
      <Card className="budgie-card border-red-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-red-600">
            <AlertTriangle className="w-5 h-5" />
            Güvenlik ve Çıkış İşlemleri
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <Button 
            onClick={() => setShowLogoutConfirm(true)}
            variant="destructive" 
            className="w-full"
          >
            <LogOut className="w-4 h-4 mr-2" />
            Çıkış Yap
          </Button>
          
          <AlertDialog open={showDeleteAccount} onOpenChange={setShowDeleteAccount}>
            <AlertDialogTrigger asChild>
              <Button variant="destructive" className="w-full" disabled={isDeleting}>
                <Trash2 className="w-4 h-4 mr-2" />
                {isDeleting ? 'Siliniyor...' : 'Hesabı Kalıcı Olarak Sil'}
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
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
        </CardContent>
      </Card>

      {/* Logout Confirmation Dialog */}
      {showLogoutConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-md">
            <CardHeader>
              <CardTitle>Çıkış Yapmak İstediğinizden Emin misiniz?</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Bu işlem sizi güvenli bir şekilde çıkış yapacaktır. Tekrar giriş yapmak için kullanıcı adı ve şifrenizi girmeniz gerekecektir.
              </p>
              <div className="flex gap-2">
                <Button 
                  onClick={() => setShowLogoutConfirm(false)}
                  variant="outline"
                  className="flex-1"
                >
                  İptal
                </Button>
                <Button 
                  onClick={handleSignOut}
                  variant="destructive"
                  className="flex-1"
                >
                  Evet, Çıkış Yap
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
};

export default AccountSettings; 