import { useState } from 'react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { User, Camera, Upload } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { toast } from '@/components/ui/use-toast';

interface AvatarUploadProps {
  avatarUrl?: string;
  initials: string;
  displayName: string;
}

const AvatarUpload = ({ avatarUrl, initials, displayName }: AvatarUploadProps) => {
  const { user, updateProfile } = useAuth();
  const [uploading, setUploading] = useState(false);

  const uploadAvatar = async (event: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setUploading(true);

      const file = event.target.files?.[0];
      if (!file || !user) {
        return;
      }

      // Validate file type
      if (!file.type.startsWith('image/')) {
        toast({
          title: 'Hata',
          description: 'Lütfen geçerli bir resim dosyası seçin.',
          variant: 'destructive',
        });
        return;
      }

      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        toast({
          title: 'Hata',
          description: 'Dosya boyutu 5MB\'den küçük olmalıdır.',
          variant: 'destructive',
        });
        return;
      }

      const fileExt = file.name.split('.').pop();
      const filePath = `${user.id}/avatar.${fileExt}`;

      // Upload file to Supabase Storage
      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(filePath, file, { upsert: true });

      if (uploadError) {
        throw uploadError;
      }

      // Get public URL
      const { data } = supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);

      // Update profile with new avatar URL
      const { error: updateError } = await supabase
        .from('profiles')
        .update({ avatar_url: data.publicUrl })
        .eq('id', user.id);

      if (updateError) {
        throw updateError;
      }

      // Update local state if available
      if (updateProfile) {
        updateProfile({ avatar_url: data.publicUrl });
      }

      toast({
        title: 'Başarılı',
        description: 'Profil resminiz güncellendi.',
      });

    } catch (error: unknown) {
      if (error instanceof Error) {
        toast({
          title: 'Hata',
          description: error.message || 'Avatar yüklenirken bir hata oluştu.',
          variant: 'destructive',
        });
      } else {
        toast({
          title: 'Hata',
          description: 'Avatar yüklenirken bir hata oluştu.',
          variant: 'destructive',
        });
      }
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="flex flex-col items-center space-y-4">
      <div className="relative">
        <Avatar className="w-20 h-20">
          <AvatarImage src={avatarUrl || ''} />
          <AvatarFallback className="text-xl font-bold bg-primary text-primary-foreground">
            {initials || <User className="h-8 w-8" />}
          </AvatarFallback>
        </Avatar>
        
        <label htmlFor="avatar-upload" className="absolute -bottom-2 -right-2 cursor-pointer">
          <Button
            size="sm"
            className="rounded-full w-8 h-8 p-0"
            variant="secondary"
            disabled={uploading}
            asChild
          >
            <div>
              {uploading ? (
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
              ) : (
                <Camera className="w-4 h-4" />
              )}
            </div>
          </Button>
        </label>
        
        <input
          id="avatar-upload"
          type="file"
          accept="image/*"
          onChange={uploadAvatar}
          className="hidden"
          disabled={uploading}
        />
      </div>
      
      <div className="text-center">
        <h3 className="text-lg font-semibold">{displayName}</h3>
        <p className="text-sm text-muted-foreground">
          Muhabbet kuşu sevdalısı
        </p>
      </div>
      
      <label htmlFor="avatar-upload">
        <Button 
          variant="outline" 
          size="sm"
          disabled={uploading}
          className="mt-2"
          asChild
        >
          <div className="cursor-pointer">
            <Upload className="w-4 h-4 mr-2" />
            {uploading ? 'Yükleniyor...' : 'Fotoğraf Değiştir'}
          </div>
        </Button>
      </label>
    </div>
  );
};

export default AvatarUpload;