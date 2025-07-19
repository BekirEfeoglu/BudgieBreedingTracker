import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { AlertTriangle, LogOut, User, Shield, Trash2 } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useAccountDeletion } from '@/hooks/useAccountDeletion';
import { toast } from '@/components/ui/use-toast';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { ConfirmationDialog } from '@/components/ui/confirmation-dialog';
import PasswordChange from '@/components/profile/PasswordChange';

const AccountSettings = () => {
  const { profile, signOut } = useAuth();
  const { deleteAccount, isDeleting } = useAccountDeletion();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteAccount, setShowDeleteAccount] = useState(false);
  const [showPasswordChange, setShowPasswordChange] = useState(false);

  const getInitials = () => {
    const first = profile?.first_name || '';
    const last = profile?.last_name || '';
    return `${first.charAt(0)}${last.charAt(0)}`.toUpperCase();
  };

  const displayName = () => {
    const first = profile?.first_name || '';
    const last = profile?.last_name || '';
    return `${first} ${last}`.trim() || 'Kullanıcı';
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
      {/* Hesap Bilgileri */}
      <Card className="budgie-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <User className="w-5 h-5 text-primary" />
            Hesap Bilgileri
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-4 p-4 bg-muted/30 rounded-lg">
            <div className="w-12 h-12 bg-primary rounded-full flex items-center justify-center text-white font-semibold">
              {getInitials() || '🦜'}
            </div>
            <div>
              <h3 className="font-semibold">{displayName()}</h3>
              <p className="text-sm text-muted-foreground">
                Muhabbet kuşu sevdalısı
              </p>
            </div>
          </div>
          
          <Button 
            onClick={() => setShowPasswordChange(true)}
            variant="outline"
            className="w-full"
          >
            <Shield className="w-4 h-4 mr-2" />
            Şifre Değiştir
          </Button>
        </CardContent>
      </Card>

      {/* Hesap İşlemleri */}
      <Card className="budgie-card border-red-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-red-600">
            <AlertTriangle className="w-5 h-5" />
            Hesap İşlemleri
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

      {/* Password Change Modal */}
      {showPasswordChange && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-md max-h-[90vh] overflow-y-auto">
            <CardHeader>
              <CardTitle>Şifre Değiştir</CardTitle>
            </CardHeader>
            <CardContent>
              <PasswordChange />
              <Button 
                onClick={() => setShowPasswordChange(false)}
                className="w-full mt-4"
              >
                Kapat
              </Button>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
};

export default AccountSettings; 