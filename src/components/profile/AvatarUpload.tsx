import { useState, useRef } from 'react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Camera, Upload, X, Loader2 } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { toast } from '@/components/ui/use-toast';
import { sanitizeFileUpload } from '@/utils/inputSanitization';

interface AvatarUploadProps {
  avatarUrl?: string | null;
  initials: string;
  displayName: string;
}

const AvatarUpload = ({ avatarUrl, initials, displayName }: AvatarUploadProps) => {
  const { updateProfile } = useAuth();
  const [isUploading, setIsUploading] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Dosya validasyonu
    const validation = sanitizeFileUpload(file);
    if (!validation.isValid) {
      toast({
        title: 'Dosya Hatası',
        description: validation.error,
        variant: 'destructive',
      });
      return;
    }

    // Preview oluştur
    const reader = new FileReader();
    reader.onload = (e) => {
      setPreviewUrl(e.target?.result as string);
    };
    reader.readAsDataURL(file);

    // Dosyayı yükle
    await uploadAvatar(file);
  };

  const uploadAvatar = async (file: File) => {
    setIsUploading(true);
    
    try {
      console.log('🔄 Avatar yükleniyor...', { fileName: file.name, fileSize: file.size });
      
      // Dosyayı base64'e çevir (gerçek uygulamada Supabase Storage kullanılır)
      const reader = new FileReader();
      reader.onload = async (e) => {
        const base64 = e.target?.result as string;
        
        // Profili güncelle
        const { error } = await updateProfile({
          avatar_url: base64,
        });

        if (error) {
          console.error('❌ Avatar yükleme hatası:', error);
          toast({
            title: 'Yükleme Hatası',
            description: error.message || 'Avatar yüklenirken bir hata oluştu.',
            variant: 'destructive',
          });
        } else {
          console.log('✅ Avatar başarıyla güncellendi');
          toast({
            title: 'Başarılı',
            description: 'Avatar başarıyla güncellendi.',
          });
        }
      };
      reader.readAsDataURL(file);
    } catch (error) {
      console.error('❌ Avatar yükleme exception:', error);
      toast({
        title: 'Hata',
        description: 'Avatar yüklenirken bir hata oluştu.',
        variant: 'destructive',
      });
    } finally {
      setIsUploading(false);
    }
  };

  const removeAvatar = async () => {
    setIsUploading(true);
    
    try {
      console.log('🔄 Avatar kaldırılıyor...');
      
      const { error } = await updateProfile({
        avatar_url: null,
      });

      if (error) {
        console.error('❌ Avatar kaldırma hatası:', error);
        toast({
          title: 'Kaldırma Hatası',
          description: error.message || 'Avatar kaldırılırken bir hata oluştu.',
          variant: 'destructive',
        });
      } else {
        console.log('✅ Avatar başarıyla kaldırıldı');
        setPreviewUrl(null);
        toast({
          title: 'Başarılı',
          description: 'Avatar başarıyla kaldırıldı.',
        });
      }
    } catch (error) {
      console.error('❌ Avatar kaldırma exception:', error);
      toast({
        title: 'Hata',
        description: 'Avatar kaldırılırken bir hata oluştu.',
        variant: 'destructive',
      });
    } finally {
      setIsUploading(false);
    }
  };

  const currentAvatarUrl = previewUrl || avatarUrl;

  return (
    <div className="relative group">
      {/* Avatar Display */}
      <Avatar className="h-24 w-24 border-4 border-white shadow-xl ring-4 ring-blue-100 group-hover:ring-blue-200 transition-all duration-300">
        <AvatarImage 
          src={currentAvatarUrl || undefined} 
          alt={displayName} 
          className="object-cover"
        />
        <AvatarFallback className="text-2xl font-bold bg-gradient-to-br from-blue-500 to-indigo-600 text-white">
          {initials || 'U'}
        </AvatarFallback>
      </Avatar>
      
      {/* Upload Overlay */}
      <div 
        className="absolute inset-0 flex items-center justify-center bg-black/60 rounded-full opacity-0 group-hover:opacity-100 transition-all duration-300 cursor-pointer"
        onClick={() => fileInputRef.current?.click()}
      >
        <div className="bg-white/20 backdrop-blur-sm rounded-full p-2">
          <Camera className="w-6 h-6 text-white" />
        </div>
      </div>
      
      {/* Loading Overlay */}
      {isUploading && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/60 rounded-full backdrop-blur-sm">
          <div className="bg-white/20 backdrop-blur-sm rounded-full p-2">
            <Loader2 className="w-6 h-6 text-white animate-spin" />
          </div>
        </div>
      )}

      {/* Remove Button */}
      {currentAvatarUrl && !isUploading && (
        <Button
          size="sm"
          variant="destructive"
          onClick={removeAvatar}
          className="absolute -top-2 -right-2 w-6 h-6 p-0 rounded-full shadow-lg hover:scale-110 transition-transform"
        >
          <X className="w-3 h-3" />
        </Button>
      )}

      {/* Hidden File Input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        onChange={handleFileSelect}
        className="hidden"
      />
    </div>
  );
};

export default AvatarUpload; 