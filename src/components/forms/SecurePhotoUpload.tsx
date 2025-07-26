import { useRef, useState } from 'react';
import { Camera, Upload, AlertCircle } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { toast } from '@/components/ui/use-toast';

interface SecurePhotoUploadProps {
  selectedPhoto: string | null;
  onPhotoSelect: (photo: string) => void;
  maxSizeMB?: number;
  allowedTypes?: string[];
}

const SecurePhotoUpload = ({ 
  selectedPhoto, 
  onPhotoSelect,
  maxSizeMB = 5,
  allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
}: SecurePhotoUploadProps) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isValidating, setIsValidating] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);

  const validateFile = (file: File): Promise<boolean> => {
    return new Promise((resolve) => {
      setValidationError(null);
      
      // Check file type
      if (!allowedTypes.includes(file.type)) {
        setValidationError(`Desteklenmeyen dosya formatı. İzin verilen: ${allowedTypes.join(', ')}`);
        resolve(false);
        return;
      }

      // Check file size
      const maxSizeBytes = maxSizeMB * 1024 * 1024;
      if (file.size > maxSizeBytes) {
        setValidationError(`Dosya boyutu çok büyük. Maksimum: ${maxSizeMB}MB`);
        resolve(false);
        return;
      }

      // Validate image dimensions and content
      const img = new Image();
      const url = URL.createObjectURL(file);
      
      img.onload = () => {
        URL.revokeObjectURL(url);
        
        // Check minimum dimensions
        if (img.width < 100 || img.height < 100) {
          setValidationError('Fotoğraf en az 100x100 piksel olmalıdır');
          resolve(false);
          return;
        }

        // Check maximum dimensions
        if (img.width > 4000 || img.height > 4000) {
          setValidationError('Fotoğraf en fazla 4000x4000 piksel olabilir');
          resolve(false);
          return;
        }

        resolve(true);
      };

      img.onerror = () => {
        URL.revokeObjectURL(url);
        setValidationError('Geçersiz görüntü dosyası');
        resolve(false);
      };

      img.src = url;
    });
  };

  const sanitizeFileName = (fileName: string): string => {
    // Remove or replace dangerous characters
    return fileName
      .replace(/[^a-zA-Z0-9._-]/g, '_')
      .replace(/_{2,}/g, '_')
      .slice(0, 100); // Limit length
  };

  const handlePhotoSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setIsValidating(true);
    
    try {
      const isValid = await validateFile(file);
      if (!isValid) {
        toast({
          title: 'Geçersiz Dosya',
          description: validationError || 'Dosya doğrulanamadı',
          variant: 'destructive',
        });
        return;
      }

      // Sanitize file name
      const sanitizedName = sanitizeFileName(file.name);
      
      // Create a new file with sanitized name
      const sanitizedFile = new File([file], sanitizedName, { type: file.type });

      const reader = new FileReader();
      reader.onload = (e) => {
        const result = e.target?.result as string;
        onPhotoSelect(result);
        toast({
          title: 'Başarılı',
          description: 'Fotoğraf yüklendi',
        });
      };
      
      reader.onerror = () => {
        setValidationError('Dosya okuma hatası');
        toast({
          title: 'Hata',
          description: 'Dosya okunamadı',
          variant: 'destructive',
        });
      };
      
      reader.readAsDataURL(sanitizedFile);
    } catch (error) {
      console.error('Photo upload error:', error);
      setValidationError('Beklenmedik hata oluştu');
      toast({
        title: 'Hata',
        description: 'Fotoğraf yüklenirken hata oluştu',
        variant: 'destructive',
      });
    } finally {
      setIsValidating(false);
      // Clear input for security
      if (event.target) {
        event.target.value = '';
      }
    }
  };

  return (
    <div className="flex flex-col items-center space-y-3">
      <div 
        className={`w-24 h-24 rounded-full border-2 border-dashed flex items-center justify-center cursor-pointer transition-all duration-200 ${
          isValidating 
            ? 'border-yellow-400 bg-yellow-50' 
            : validationError 
              ? 'border-red-400 bg-red-50' 
              : 'border-muted-foreground hover:border-primary hover:bg-primary/5'
        }`}
        onClick={() => !isValidating && fileInputRef.current?.click()}
      >
        {selectedPhoto ? (
          <img 
            src={selectedPhoto} 
            alt="Kuş fotoğrafı" 
            className="w-full h-full rounded-full object-cover"
            loading="lazy"
          />
        ) : isValidating ? (
          <div className="flex flex-col items-center gap-1">
            <Upload className="w-6 h-6 text-yellow-600 animate-pulse" />
            <span className="text-xs text-yellow-600">Doğrulanıyor...</span>
          </div>
        ) : (
          <Camera className="w-8 h-8 text-muted-foreground" />
        )}
      </div>

      <input
        ref={fileInputRef}
        type="file"
        accept={allowedTypes.join(',')}
        onChange={handlePhotoSelect}
        className="hidden"
        disabled={isValidating}
      />

      <div className="text-center space-y-1">
        <p className="text-xs text-muted-foreground">
          Fotoğraf yüklemek için tıklayın
        </p>
        <p className="text-xs text-muted-foreground">
          Maksimum: {maxSizeMB}MB | Format: JPG, PNG, WebP
        </p>
      </div>

      {validationError && (
        <Alert variant="destructive" className="max-w-xs">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription className="text-xs">
            {validationError}
          </AlertDescription>
        </Alert>
      )}
    </div>
  );
};

export default SecurePhotoUpload;