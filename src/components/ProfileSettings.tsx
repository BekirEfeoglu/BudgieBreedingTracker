
import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useAuth } from '@/hooks/useAuth';
import { useSubscription } from '@/hooks/subscription/useSubscription';
import { User, ArrowLeft, LogOut, AlertTriangle, Crown, Star, Heart, Mail, Calendar, Shield, Settings, Edit3, Camera } from 'lucide-react';
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
  const { profile, signOut, user } = useAuth();
  const { isPremium, isTrial, trialInfo } = useSubscription();
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

  const getSubscriptionStatus = () => {
    if (isPremium) {
      return {
        text: 'Premium Üye',
        icon: Crown,
        color: 'bg-gradient-to-r from-yellow-400 via-orange-500 to-red-500 text-white shadow-lg',
        description: 'Tüm premium özelliklere erişiminiz var',
        bgGradient: 'from-yellow-50 to-orange-50',
        borderColor: 'border-yellow-200'
      };
    } else if (isTrial) {
      return {
        text: `Trial - ${trialInfo.days_remaining}g kaldı`,
        icon: Star,
        color: 'bg-gradient-to-r from-blue-400 via-purple-500 to-indigo-500 text-white shadow-lg',
        description: `${trialInfo.days_remaining} gün trial süreniz kaldı`,
        bgGradient: 'from-blue-50 to-purple-50',
        borderColor: 'border-blue-200'
      };
    } else {
      return {
        text: 'Ücretsiz Üye',
        icon: Heart,
        color: 'bg-gradient-to-r from-gray-400 via-gray-500 to-gray-600 text-white shadow-lg',
        description: 'Temel özelliklerle sınırlı',
        bgGradient: 'from-gray-50 to-slate-50',
        borderColor: 'border-gray-200'
      };
    }
  };

  const subscriptionStatus = getSubscriptionStatus();

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

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('tr-TR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50">
      <div className="mobile-container py-6 max-w-4xl px-4 sm:px-6">
        {/* Modern Header */}
        <div className="flex items-center gap-4 mb-8">
          {onBack && (
            <Button
              variant="ghost"
              size="sm"
              onClick={onBack}
              className="p-3 hover:bg-white/20 rounded-full backdrop-blur-sm touch-target transition-all duration-200 hover:scale-105"
              aria-label="Geri"
            >
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-gradient-to-br from-primary to-primary/80 rounded-2xl flex items-center justify-center text-2xl shadow-lg flex-shrink-0">
              👤
            </div>
            <div className="min-w-0 flex-1">
              <h1 className="mobile-title sm:text-3xl font-bold text-foreground">Profil</h1>
              <p className="text-muted-foreground mobile-text-sm">Hesap bilgilerinizi yönetin</p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Sol Kolon - Profil Özeti */}
          <div className="lg:col-span-1 space-y-6">
            {/* Profil Kartı */}
            <Card className="enhanced-card shadow-xl backdrop-blur-sm bg-white/95 border-2 border-primary/20 hover:shadow-2xl transition-all duration-300">
              <CardContent className="pt-8 pb-6">
                <div className="text-center space-y-6">
                  {/* Avatar */}
                  <div className="relative mx-auto">
                    <div className="w-24 h-24 bg-gradient-to-br from-primary/20 to-primary/40 rounded-full flex items-center justify-center mx-auto mb-4 shadow-lg">
                      <AvatarUpload
                        avatarUrl={profile?.avatar_url}
                        initials={getInitials()}
                        displayName={displayName()}
                      />
                    </div>
                    <Button
                      size="sm"
                      variant="secondary"
                      className="absolute -bottom-2 -right-2 rounded-full w-8 h-8 p-0 shadow-lg hover:scale-110 transition-transform"
                    >
                      <Camera className="w-4 h-4" />
                    </Button>
                  </div>

                  {/* Kullanıcı Bilgileri */}
                  <div className="space-y-3">
                    <h2 className="text-2xl font-bold text-foreground">{displayName()}</h2>
                    <p className="text-muted-foreground flex items-center justify-center gap-2">
                      <Mail className="w-4 h-4" />
                      {user?.email}
                    </p>
                    <p className="text-sm text-muted-foreground italic">
                      Muhabbet kuşu sevdalısı
                    </p>
                  </div>

                  {/* Abonelik Durumu */}
                  <div className="space-y-3">
                    <Badge className={`${subscriptionStatus.color} px-4 py-2 text-sm font-bold`}>
                      <subscriptionStatus.icon className="w-4 h-4 mr-1" />
                      {subscriptionStatus.text}
                    </Badge>
                    <p className="text-xs text-muted-foreground">
                      {subscriptionStatus.description}
                    </p>
                  </div>

                  {/* Hesap Bilgileri */}
                  <div className="space-y-2 text-sm text-muted-foreground">
                    <div className="flex items-center justify-center gap-2">
                      <span className="font-medium">ID:</span>
                      <span className="font-mono text-xs">{profile?.id?.slice(0, 8)}...</span>
                    </div>
                    {profile?.updated_at && (
                      <div className="flex items-center justify-center gap-2">
                        <Calendar className="w-4 h-4" />
                        <span>Son güncelleme: {formatDate(profile.updated_at)}</span>
                      </div>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Hızlı İşlemler */}
            <Card className="enhanced-card shadow-lg backdrop-blur-sm bg-white/95">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <Settings className="w-5 h-5 text-primary" />
                  Hızlı İşlemler
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <Button variant="outline" className="w-full justify-start" onClick={() => document.getElementById('profile-form')?.scrollIntoView({ behavior: 'smooth' })}>
                  <Edit3 className="w-4 h-4 mr-2" />
                  Profil Düzenle
                </Button>
                <Button variant="outline" className="w-full justify-start" onClick={() => document.getElementById('password-change')?.scrollIntoView({ behavior: 'smooth' })}>
                  <Shield className="w-4 h-4 mr-2" />
                  Şifre Değiştir
                </Button>
              </CardContent>
            </Card>
          </div>

          {/* Sağ Kolon - Detaylı Ayarlar */}
          <div className="lg:col-span-2 space-y-6">
            {/* Profil Formu */}
            <Card id="profile-form" className="enhanced-card shadow-lg backdrop-blur-sm bg-white/95">
              <CardHeader>
                <CardTitle className="flex items-center gap-3 mobile-title">
                  <User className="w-6 h-6 text-primary" />
                  Kişisel Bilgiler
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ProfileForm
                  initialFirstName={profile?.first_name || ''}
                  initialLastName={profile?.last_name || ''}
                />
              </CardContent>
            </Card>

            {/* Şifre Değiştir */}
            <Card id="password-change" className="enhanced-card shadow-lg backdrop-blur-sm bg-white/95">
              <CardHeader>
                <CardTitle className="flex items-center gap-3 mobile-title">
                  <Shield className="w-6 h-6 text-primary" />
                  Güvenlik
                </CardTitle>
              </CardHeader>
              <CardContent>
                <PasswordChange />
              </CardContent>
            </Card>

            <ProfileInfoNote />

            {/* Hesap İşlemleri */}
            <div className="space-y-4">
              <Card className="enhanced-card shadow-lg backdrop-blur-sm bg-white/95 border-red-200 hover:shadow-xl transition-all duration-300">
                <CardContent className="pt-6">
                  <div className="text-center space-y-4">
                    <div className="w-16 h-16 bg-gradient-to-br from-red-100 to-red-200 rounded-full flex items-center justify-center mx-auto shadow-lg">
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
                      className="w-full touch-target mobile-body font-medium hover:scale-105 transition-transform"
                    >
                      <LogOut className="w-5 h-5 mr-2" />
                      Çıkış Yap
                    </Button>
                  </div>
                </CardContent>
              </Card>

              <Card className="enhanced-card shadow-lg backdrop-blur-sm bg-white/95 border-red-200 hover:shadow-xl transition-all duration-300">
                <CardContent className="pt-6">
                  <div className="text-center space-y-4">
                    <div className="w-16 h-16 bg-gradient-to-br from-red-100 to-red-200 rounded-full flex items-center justify-center mx-auto shadow-lg">
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
                          className="w-full touch-target mobile-body font-medium hover:scale-105 transition-transform"
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
