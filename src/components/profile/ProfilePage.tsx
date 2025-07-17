import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { useAuth } from '@/hooks/useAuth';
import { toast } from '@/components/ui/use-toast';
import { ArrowLeft, Camera, Save, LogOut, Edit, Lock, AlertTriangle } from 'lucide-react';
import { ConfirmationDialog } from '@/components/ui/confirmation-dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Camera as CapacitorCamera, CameraResultType, CameraSource } from '@capacitor/camera';
import { supabase } from '@/integrations/supabase/client';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';

interface ProfilePageProps {
  onBack: () => void;
}

const ProfilePage = ({ onBack }: ProfilePageProps) => {
  const { profile, updateProfile, signOut } = useAuth();
  const [firstName, setFirstName] = useState(profile?.first_name || '');
  const [lastName, setLastName] = useState(profile?.last_name || '');
  const [loading, setLoading] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const [showPasswordChange, setShowPasswordChange] = useState(false);
  const [showDeleteAccount, setShowDeleteAccount] = useState(false);
  const [showPhotoDialog, setShowPhotoDialog] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState(profile?.avatar_url || '');
  const [uploading, setUploading] = useState(false);

  // Profile değiştiğinde state'leri güncelle
  useEffect(() => {
    if (profile) {
      setFirstName(profile.first_name || '');
      setLastName(profile.last_name || '');
      setAvatarUrl(profile.avatar_url || '');
    }
  }, [profile]);

  const handleSave = async () => {
    setLoading(true);
    try {
      const { error } = await updateProfile({
        first_name: firstName,
        last_name: lastName,
      });

      if (error) {
        toast({
          title: 'Hata',
          description: 'Profil güncellenirken bir hata oluştu.',
          variant: 'destructive',
        });
      } else {
        toast({
          title: 'Başarılı!',
          description: 'Profiliniz güncellendi.',
        });
        setIsEditing(false);
      }
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

  const handleSignOut = async () => {
    try {
      await signOut();
      toast({
        title: 'Çıkış Yapıldı',
        description: 'Başarıyla çıkış yaptınız.',
      });
    } catch (error) {
      toast({
        title: 'Hata',
        description: 'Çıkış yapılırken bir hata oluştu.',
        variant: 'destructive',
      });
    }
  };

  const handleDeleteAccount = () => {
    // Account deletion would be implemented here
    setShowDeleteAccount(false);
    toast({
      title: 'Hesap Silme Talebi',
      description: 'Hesap silme özelliği yakında eklenecek.',
      variant: 'destructive',
    });
  };

  const getInitials = () => {
    const first = firstName || profile?.first_name || '';
    const last = lastName || profile?.last_name || '';
    return `${first.charAt(0)}${last.charAt(0)}`.toUpperCase();
  };

  const displayName = () => {
    const first = firstName || profile?.first_name || '';
    const last = lastName || profile?.last_name || '';
    return `${first} ${last}`.trim() || 'Kullanıcı';
  };

  const handleEditToggle = () => {
    if (isEditing) {
      // Cancel editing - reset values
      setFirstName(profile?.first_name || '');
      setLastName(profile?.last_name || '');
    }
    setIsEditing(!isEditing);
  };

  // Fotoğrafı Supabase Storage'a yükle
  const uploadPhotoToSupabase = async (base64Data: string) => {
    setUploading(true);
    try {
      const fileName = `avatars/${profile?.id || 'user'}_${Date.now()}.jpeg`;
      const { data, error } = await supabase.storage.from('avatars').upload(fileName, base64Data, {
        contentType: 'image/jpeg',
        upsert: true,
      });
      if (error) throw error;
      // Public URL al
      const { data: publicUrlData } = supabase.storage.from('avatars').getPublicUrl(fileName);
      if (publicUrlData?.publicUrl) {
        setAvatarUrl(publicUrlData.publicUrl);
        await updateProfile({ avatar_url: publicUrlData.publicUrl });
        toast({ title: 'Profil fotoğrafı güncellendi!' });
      }
    } catch (error) {
      toast({ title: 'Fotoğraf yüklenemedi', description: String(error), variant: 'destructive' });
    } finally {
      setUploading(false);
      setShowPhotoDialog(false);
    }
  };

  // Kamera veya galeriden fotoğraf seç
  const handlePhotoPick = async (source: CameraSource) => {
    try {
      const photo = await CapacitorCamera.getPhoto({
        quality: 80,
        allowEditing: true,
        resultType: CameraResultType.Base64,
        source,
      });
      if (photo.base64String) {
        const base64Data = `data:image/jpeg;base64,${photo.base64String}`;
        await uploadPhotoToSupabase(base64Data);
      }
    } catch (error) {
      toast({ title: 'Fotoğraf seçilemedi', description: String(error), variant: 'destructive' });
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-budgie-cream to-budgie-warm">
      <div className="container mx-auto px-4 py-6 max-w-2xl">
        {/* Header */}
        <div className="flex items-center gap-4 mb-6">
          <Button
            variant="ghost"
            onClick={onBack}
            className="p-2 hover:bg-white/20"
          >
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 budgie-gradient rounded-full flex items-center justify-center text-lg">
              🦜
            </div>
            <h1 className="text-2xl font-bold text-foreground">Profil</h1>
          </div>
        </div>

        <div className="space-y-6">
          {/* Profile Picture Section */}
          <Card className="budgie-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <span>Profil Bilgileri</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col items-center space-y-6">
              <div className="relative">
                <Avatar className="w-24 h-24">
                  <AvatarImage src={avatarUrl} />
                  <AvatarFallback className="text-2xl font-bold bg-primary text-primary-foreground">
                    {getInitials() || '🦜'}
                  </AvatarFallback>
                </Avatar>
                <Button
                  size="sm"
                  className="absolute -bottom-2 -right-2 rounded-full w-8 h-8 p-0"
                  variant="secondary"
                  onClick={() => setShowPhotoDialog(true)}
                  disabled={uploading}
                >
                  <Camera className="w-4 h-4" />
                </Button>
                {/* Fotoğraf seçme modalı */}
                <Dialog open={showPhotoDialog} onOpenChange={setShowPhotoDialog}>
                  <DialogContent aria-describedby="profile-photo-description">
                    <DialogHeader>
                      <DialogTitle>Profil Fotoğrafı</DialogTitle>
                      <div id="profile-photo-description" className="sr-only">
                        Profil fotoğrafı seçme seçenekleri
                      </div>
                    </DialogHeader>
                    <div className="flex flex-col gap-4 items-center">
                      <Button onClick={() => handlePhotoPick(CameraSource.Camera)} disabled={uploading} className="w-full">
                        Kameradan Çek
                      </Button>
                      <Button onClick={() => handlePhotoPick(CameraSource.Photos)} disabled={uploading} className="w-full">
                        Galeriden Seç
                      </Button>
                    </div>
                    <DialogFooter>
                      <Button variant="outline" onClick={() => setShowPhotoDialog(false)} disabled={uploading}>İptal</Button>
                    </DialogFooter>
                  </DialogContent>
                </Dialog>
              </div>
              
              <div className="text-center">
                <h3 className="text-xl font-semibold mb-2">{displayName()}</h3>
                <p className="text-sm text-muted-foreground">
                  Muhabbet kuşu sevdalısı
                </p>
              </div>

              {/* Name Fields */}
              <div className="w-full max-w-md space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="firstName">Ad</Label>
                    <Input
                      id="firstName"
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      placeholder="Adınız"
                      disabled={!isEditing}
                      className={!isEditing ? "bg-muted" : ""}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="lastName">Soyad</Label>
                    <Input
                      id="lastName"
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      placeholder="Soyadınız"
                      disabled={!isEditing}
                      className={!isEditing ? "bg-muted" : ""}
                    />
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex gap-2">
                  {isEditing ? (
                    <>
                      <Button 
                        onClick={handleSave} 
                        className="flex-1 budgie-button" 
                        disabled={loading}
                      >
                        <Save className="w-4 h-4 mr-2" />
                        {loading ? 'Kaydediliyor...' : 'Kaydet'}
                      </Button>
                      <Button 
                        onClick={handleEditToggle}
                        variant="outline"
                        className="flex-1"
                      >
                        İptal
                      </Button>
                    </>
                  ) : (
                    <Button 
                      onClick={handleEditToggle}
                      className="w-full budgie-button"
                    >
                      <Edit className="w-4 h-4 mr-2" />
                      Profili Düzenle
                    </Button>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Action Buttons */}
          <div className="space-y-4">
            <Card className="budgie-card">
              <CardContent className="pt-6">
                <Button 
                  onClick={() => setShowPasswordChange(true)}
                  variant="outline"
                  className="w-full"
                >
                  <Lock className="w-4 h-4 mr-2" />
                  Şifre Değiştir
                </Button>
              </CardContent>
            </Card>

            <Card className="budgie-card border-red-200">
              <CardContent className="pt-6 space-y-3">
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
                    <Button variant="destructive" className="w-full">
                      <AlertTriangle className="w-4 h-4 mr-2" />
                      Hesabı Sil
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Hesabı Sil</AlertDialogTitle>
                      <AlertDialogDescription>
                        Bu işlem geri alınamaz. Hesabınız ve tüm verileriniz kalıcı olarak silinecektir.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>İptal</AlertDialogCancel>
                      <AlertDialogAction onClick={handleDeleteAccount}>
                        Hesabı Sil
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
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

      {/* Password Change Modal Placeholder */}
      {showPasswordChange && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-md">
            <CardHeader>
              <CardTitle>Şifre Değiştir</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-muted-foreground">
                Şifre değiştirme özelliği yakında eklenecek.
              </p>
              <Button 
                onClick={() => setShowPasswordChange(false)}
                className="w-full"
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

export default ProfilePage;
