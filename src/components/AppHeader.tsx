
import { useState, useEffect } from 'react';
import { MessageSquare, Settings, User, LogOut, Menu, X, Edit3, Shield, AlertTriangle, Trash2, Camera, Crown } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger, DropdownMenuLabel } from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { useAuth } from '@/hooks/useAuth';
import { useAccountDeletion } from '@/hooks/useAccountDeletion';
import { useSubscription } from '@/hooks/subscription/useSubscription';
import { SyncStatus } from '@/components/ui/sync-status';
import { toast } from '@/components/ui/use-toast';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import ProfileForm from '@/components/profile/ProfileForm';
import AvatarUpload from '@/components/profile/AvatarUpload';
import PasswordChange from '@/components/profile/PasswordChange';

interface AppHeaderProps {
  onTabChange: (tab: string) => void;
  onToggleSidebar: () => void;
  isSidebarOpen: boolean;
}

const AppHeader = ({ onTabChange, onToggleSidebar, isSidebarOpen }: AppHeaderProps) => {
  const { user, profile, signOut } = useAuth();
  const { deleteAccount, isDeleting } = useAccountDeletion();
  const { isPremium, isTrial, trialInfo, error: subscriptionError } = useSubscription();
  const [isMobile, setIsMobile] = useState(false);
  const [showProfileEdit, setShowProfileEdit] = useState(false);
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showDeleteAccount, setShowDeleteAccount] = useState(false);
  const [showPasswordChange, setShowPasswordChange] = useState(false);

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

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

  const getInitials = (firstName?: string | null, lastName?: string | null) => {
    if (!firstName && !lastName) return 'U';
    return `${firstName?.[0] || ''}${lastName?.[0] || ''}`.toUpperCase();
  };

  const getDisplayName = () => {
    if (profile?.first_name || profile?.last_name) {
      return `${profile.first_name || ''} ${profile.last_name || ''}`.trim();
    }
    return user?.email?.split('@')[0] || 'Kullanıcı';
  };

  return (
    <>
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto px-4">
        <div className="flex h-14 items-center justify-between">
          {/* Left Section */}
          <div className="flex items-center space-x-4">
            {/* Mobile Menu Toggle */}
            <Button
              variant="ghost"
              size="sm"
              className="md:hidden"
              onClick={onToggleSidebar}
            >
              {isSidebarOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </Button>

            {/* Logo/Title */}
            <div className="flex items-center space-x-2">
                {/* Logo removed */}
            </div>
          </div>

            {/* Center Section - Sync Status */}
            <div className="flex items-center gap-4">
              <SyncStatus />
            </div>

            {/* Right Section */}
            <div className="flex items-center space-x-3">
              {/* Subscription Status Badge */}
              <div className="hidden sm:flex items-center gap-2">
                {isPremium ? (
                  <Badge variant="default" className="bg-gradient-to-r from-yellow-500 to-orange-500 text-white border-0">
                    <Crown className="w-3 h-3 mr-1" />
                    Premium
                  </Badge>
                ) : (
                  <Badge variant="outline" className="text-gray-600 border-gray-300">
                    <span className="w-2 h-2 bg-gray-400 rounded-full mr-1" />
                    Free
                  </Badge>
                )}
                {isTrial && (
                  <Badge variant="secondary" className="text-xs bg-blue-100 text-blue-800">
                    {trialInfo.days_remaining}g deneme
                  </Badge>
                )}
              </div>

              {/* Premium Upgrade Button */}
              {!isPremium && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => onTabChange('premium')}
                  className="hidden sm:flex items-center gap-2 bg-gradient-to-r from-yellow-50 to-orange-50 border-yellow-200 hover:from-yellow-100 hover:to-orange-100"
                >
                  <Crown className="w-4 h-4 text-yellow-600" />
                  <span className="text-yellow-700 font-medium">Premium'a Geç</span>
                </Button>
              )}
            {/* User Menu */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" className="relative h-8 w-8 rounded-full">
                  <Avatar className="h-8 w-8">
                    <AvatarImage src={profile?.avatar_url || undefined} alt={getDisplayName()} />
                    <AvatarFallback className="text-xs">
                      {getInitials(profile?.first_name, profile?.last_name)}
                    </AvatarFallback>
                  </Avatar>
                </Button>
              </DropdownMenuTrigger>
                <DropdownMenuContent className="w-80" align="end" forceMount>
                  {/* User Info Section */}
                  <div className="p-4 border-b">
                    <div className="flex items-center gap-3">
                      <div className="relative group cursor-pointer" onClick={() => setShowProfileEdit(true)}>
                        <Avatar className="h-12 w-12 border-2 border-transparent group-hover:border-primary transition-colors">
                          <AvatarImage src={profile?.avatar_url || undefined} alt={getDisplayName()} />
                          <AvatarFallback className="text-sm">
                            {getInitials(profile?.first_name, profile?.last_name)}
                          </AvatarFallback>
                        </Avatar>
                        <div className="absolute inset-0 flex items-center justify-center bg-black/30 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                          <Camera className="w-4 h-4 text-white" />
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium leading-none truncate">{getDisplayName()}</p>
                        <p className="text-xs leading-none text-muted-foreground truncate">
                    {user?.email}
                  </p>
                        <p className="text-xs leading-none text-muted-foreground mt-1">
                          Muhabbet kuşu sevdalısı
                        </p>
                        <div className="flex items-center gap-2 mt-1">
                          {isPremium ? (
                            <Badge variant="default" className="text-xs bg-gradient-to-r from-yellow-500 to-orange-500 text-white border-0">
                              <Crown className="w-2 h-2 mr-1" />
                              Premium
                            </Badge>
                          ) : (
                            <Badge variant="outline" className="text-xs text-gray-600 border-gray-300">
                              <span className="w-1.5 h-1.5 bg-gray-400 rounded-full mr-1" />
                              Free
                            </Badge>
                          )}
                          {isTrial && (
                            <Badge variant="secondary" className="text-xs bg-blue-100 text-blue-800">
                              {trialInfo.days_remaining}g deneme
                            </Badge>
                          )}
                        </div>
                        <p className="text-xs leading-none text-muted-foreground mt-1">
                          ID: {user?.id?.slice(0, 8)}...
                        </p>
                        <p className="text-xs leading-none text-muted-foreground">
                          Son giriş: {new Date(user?.last_sign_in_at || '').toLocaleString('tr-TR')}
                        </p>
                      </div>
                    </div>
                  </div>

                                  {/* Hesap Bilgileri */}
                <div className="p-3 border-b bg-blue-50/50">
                  <div className="flex items-start gap-2">
                    <div className="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                      <Shield className="w-3 h-3 text-blue-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-medium text-blue-800 mb-2">
                        Hesap Bilgileri
                      </p>
                      <div className="space-y-2">
                        <Button 
                          variant="outline" 
                          size="sm" 
                          className="w-full text-xs h-7 bg-white/50 border-blue-200 text-blue-700 hover:bg-blue-50"
                          onClick={() => setShowPasswordChange(true)}
                        >
                          <Shield className="w-3 h-3 mr-1" />
                          Şifre Değiştir
                        </Button>
                      </div>
                    </div>
                  </div>
                </div>

                  {/* Quick Actions */}
                  <div className="p-2">
                    <DropdownMenuItem onClick={() => setShowProfileEdit(true)}>
                      <Edit3 className="mr-2 h-4 w-4" />
                      Profil Düzenle
                    </DropdownMenuItem>
                    <DropdownMenuItem onClick={() => onTabChange('settings')}>
                      <Settings className="mr-2 h-4 w-4" />
                      Ayarlar
                </DropdownMenuItem>
                  </div>

                <DropdownMenuSeparator />

                  {/* Account Actions */}
                  <div className="p-2">
                    <DropdownMenuLabel className="text-xs text-muted-foreground px-2 py-1">
                      Hesap İşlemleri
                    </DropdownMenuLabel>
                    <DropdownMenuItem 
                      onClick={() => setShowLogoutConfirm(true)}
                      className="text-red-600 focus:text-red-600"
                    >
                  <LogOut className="mr-2 h-4 w-4" />
                  Çıkış Yap
                </DropdownMenuItem>
                    <AlertDialog open={showDeleteAccount} onOpenChange={setShowDeleteAccount}>
                      <AlertDialogTrigger asChild>
                        <DropdownMenuItem 
                          className="text-red-600 focus:text-red-600"
                          disabled={isDeleting}
                          onSelect={(e) => e.preventDefault()}
                        >
                          <Trash2 className="mr-2 h-4 w-4" />
                          {isDeleting ? 'Siliniyor...' : 'Hesabı Sil'}
                        </DropdownMenuItem>
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
                  </div>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </div>
    </header>

              {/* Profile Edit Modal */}
        {showProfileEdit && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 z-50">
            <Card className="w-full max-w-3xl max-h-[95vh] overflow-hidden shadow-2xl border-0 bg-white">
            {/* Modal Header */}
            <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between z-10 shadow-sm">
              <h2 className="text-xl font-semibold flex items-center gap-2">
                <Edit3 className="w-5 h-5 text-primary" />
                Profil Düzenle
              </h2>
              <Button 
                onClick={() => setShowProfileEdit(false)}
                variant="ghost"
                size="sm"
                className="hover:bg-muted"
              >
                <X className="w-4 h-4" />
              </Button>
            </div>

            {/* Modal Content */}
            <div className="overflow-y-auto max-h-[calc(95vh-80px)] bg-white">
              <div className="p-6 space-y-8">
                {/* Avatar Upload Section */}
                <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-6 border border-blue-100">
                  <h3 className="text-lg font-semibold mb-4 flex items-center gap-2 text-blue-800">
                    <Camera className="w-5 h-5" />
                    Profil Fotoğrafı
                  </h3>
                  <AvatarUpload
                    key={`avatar-${profile?.avatar_url || 'default'}`}
                    avatarUrl={profile?.avatar_url || null}
                    initials={getInitials(profile?.first_name, profile?.last_name)}
                    displayName={getDisplayName()}
                  />
                </div>

                {/* Profile Form Section */}
                <div className="bg-gradient-to-r from-green-50 to-emerald-50 rounded-xl p-6 border border-green-100">
                  <h3 className="text-lg font-semibold mb-4 flex items-center gap-2 text-green-800">
                    <User className="w-5 h-5" />
                    Kişisel Bilgiler
                  </h3>
                  <ProfileForm
                    key={`profile-${profile?.first_name}-${profile?.last_name}`}
                    initialFirstName={profile?.first_name}
                    initialLastName={profile?.last_name}
                  />
                </div>
              </div>
            </div>
          </Card>
        </div>
      )}

              {/* Logout Confirmation Dialog */}
        {showLogoutConfirm && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 z-50">
            <Card className="w-full max-w-md bg-white shadow-2xl border-0">
            <div className="p-6">
              <h2 className="text-lg font-semibold mb-4">Çıkış Yapmak İstediğinizden Emin misiniz?</h2>
              <p className="text-sm text-muted-foreground mb-6">
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
            </div>
          </Card>
        </div>
              )}

        {/* Password Change Modal */}
        {showPasswordChange && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-md flex items-center justify-center p-4 z-50">
            <Card className="w-full max-w-md max-h-[95vh] overflow-hidden shadow-2xl border-0 bg-white">
              {/* Modal Header */}
              <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between z-10 shadow-sm">
                <h2 className="text-xl font-semibold flex items-center gap-2">
                  <Shield className="w-5 h-5 text-blue-600" />
                  Şifre Değiştir
                </h2>
                <Button 
                  onClick={() => setShowPasswordChange(false)}
                  variant="ghost"
                  size="sm"
                  className="hover:bg-muted"
                >
                  <X className="w-4 h-4" />
                </Button>
              </div>

              {/* Modal Content */}
              <div className="overflow-y-auto max-h-[calc(95vh-80px)] bg-white">
                <div className="p-6">
                  <PasswordChange onClose={() => setShowPasswordChange(false)} />
                </div>
              </div>
            </Card>
          </div>
        )}
      </>
  );
};

export default AppHeader;
