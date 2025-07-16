import React, { useState, useCallback, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { 
  Upload, 
  X, 
  Image, 
  Camera, 
  CheckCircle, 
  AlertCircle,
  Loader2
} from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { cn } from '@/lib/utils';

interface PhotoUploadProps {
  onUpload: (files: File[]) => Promise<void>;
  onCancel: () => void;
  maxFiles?: number;
  acceptedTypes?: string[];
  maxSizeMB?: number;
}

interface UploadFile {
  file: File;
  id: string;
  preview: string;
  progress: number;
  status: 'uploading' | 'success' | 'error';
  error?: string;
}

const EnhancedPhotoUpload: React.FC<PhotoUploadProps> = ({
  onUpload,
  onCancel,
  maxFiles = 10,
  acceptedTypes = ['image/jpeg', 'image/png', 'image/webp'],
  maxSizeMB = 5
}) => {
  const { t } = useLanguage();
  const [uploadFiles, setUploadFiles] = useState<UploadFile[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    
    if (files.length === 0) return;

    // Validate file count
    if (uploadFiles.length + files.length > maxFiles) {
      alert(t('photo.maxFilesExceeded').replace('{max}', maxFiles.toString()));
      return;
    }

    const newUploadFiles: UploadFile[] = files.map(file => {
      // Validate file type
      if (!acceptedTypes.includes(file.type)) {
        return {
          file,
          id: Math.random().toString(36).substr(2, 9),
          preview: '',
          progress: 0,
          status: 'error',
          error: t('photo.invalidFileType')
        };
      }

      // Validate file size
      if (file.size > maxSizeMB * 1024 * 1024) {
        return {
          file,
          id: Math.random().toString(36).substr(2, 9),
          preview: '',
          progress: 0,
          status: 'error',
          error: t('photo.fileTooLarge').replace('{max}', maxSizeMB.toString())
        };
      }

      return {
        file,
        id: Math.random().toString(36).substr(2, 9),
        preview: URL.createObjectURL(file),
        progress: 0,
        status: 'uploading'
      };
    });

    setUploadFiles(prev => [...prev, ...newUploadFiles]);
  }, [uploadFiles.length, maxFiles, acceptedTypes, maxSizeMB, t]);

  const removeFile = useCallback((id: string) => {
    setUploadFiles(prev => {
      const fileToRemove = prev.find(f => f.id === id);
      if (fileToRemove?.preview) {
        URL.revokeObjectURL(fileToRemove.preview);
      }
      return prev.filter(f => f.id !== id);
    });
  }, []);

  const handleUpload = useCallback(async () => {
    const validFiles = uploadFiles.filter(f => f.status !== 'error');
    if (validFiles.length === 0) return;

    setIsUploading(true);
    
    try {
      await onUpload(validFiles.map(f => f.file));
      
      // Mark all as successful
      setUploadFiles(prev => prev.map(f => ({
        ...f,
        progress: 100,
        status: 'success' as const
      })));
      
      // Clean up after a delay
      setTimeout(() => {
        setUploadFiles([]);
        setIsUploading(false);
      }, 2000);
      
    } catch (error) {
      console.error('Upload error:', error);
      setUploadFiles(prev => prev.map(f => ({
        ...f,
        status: 'error' as const,
        error: t('photo.uploadError')
      })));
      setIsUploading(false);
    }
  }, [uploadFiles, onUpload, t]);

  const handleCameraCapture = useCallback(() => {
    if (fileInputRef.current) {
      fileInputRef.current.accept = 'image/*';
      fileInputRef.current.capture = 'environment';
      fileInputRef.current.click();
    }
  }, []);

  const validFiles = uploadFiles.filter(f => f.status !== 'error');
  const hasErrors = uploadFiles.some(f => f.status === 'error');

  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Upload className="w-5 h-5" />
          {t('photo.uploadTitle')}
        </CardTitle>
        <CardDescription>
          {t('photo.uploadDescription').replace('{max}', maxFiles.toString()).replace('{size}', maxSizeMB.toString())}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* File Input */}
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept={acceptedTypes.join(',')}
          onChange={handleFileSelect}
          className="hidden"
        />

        {/* Upload Actions */}
        <div className="flex gap-2">
          <Button
            type="button"
            variant="outline"
            onClick={() => fileInputRef.current?.click()}
            className="flex-1"
            disabled={isUploading || uploadFiles.length >= maxFiles}
          >
            <Image className="w-4 h-4 mr-2" />
            {t('photo.selectFiles')}
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={handleCameraCapture}
            className="flex-1"
            disabled={isUploading || uploadFiles.length >= maxFiles}
          >
            <Camera className="w-4 h-4 mr-2" />
            {t('photo.camera')}
          </Button>
        </div>

        {/* File List */}
        {uploadFiles.length > 0 && (
          <div className="space-y-2">
            <Label>{t('photo.selectedFiles')} ({validFiles.length}/{maxFiles})</Label>
            <div className="max-h-48 overflow-y-auto space-y-2">
              {uploadFiles.map((uploadFile) => (
                <div
                  key={uploadFile.id}
                  className={cn(
                    "flex items-center gap-2 p-2 rounded-md border",
                    uploadFile.status === 'error' && "border-destructive bg-destructive/10",
                    uploadFile.status === 'success' && "border-green-500 bg-green-50"
                  )}
                >
                  {uploadFile.preview ? (
                    <img
                      src={uploadFile.preview}
                      alt="Preview"
                      className="w-8 h-8 rounded object-cover"
                    />
                  ) : (
                    <div className="w-8 h-8 bg-muted rounded flex items-center justify-center">
                      <Image className="w-4 h-4" />
                    </div>
                  )}
                  
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{uploadFile.file.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {(uploadFile.file.size / 1024 / 1024).toFixed(2)} MB
                    </p>
                  </div>

                  <div className="flex items-center gap-1">
                    {uploadFile.status === 'uploading' && (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    )}
                    {uploadFile.status === 'success' && (
                      <CheckCircle className="w-4 h-4 text-green-500" />
                    )}
                    {uploadFile.status === 'error' && (
                      <AlertCircle className="w-4 h-4 text-destructive" />
                    )}
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => removeFile(uploadFile.id)}
                      disabled={isUploading}
                    >
                      <X className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Error Summary */}
        {hasErrors && (
          <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-md">
            <p className="text-sm text-destructive">
              {t('photo.someFilesInvalid')}
            </p>
          </div>
        )}

        {/* Form Actions */}
        <div className="flex gap-2 pt-4">
          <Button
            type="button"
            variant="outline"
            onClick={onCancel}
            className="flex-1"
            disabled={isUploading}
          >
            <X className="w-4 h-4 mr-2" />
            {t('common.cancel')}
          </Button>
          <Button
            type="button"
            onClick={handleUpload}
            className="flex-1"
            disabled={isUploading || validFiles.length === 0}
          >
            {isUploading ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                {t('photo.uploading')}
              </>
            ) : (
              <>
                <Upload className="w-4 h-4 mr-2" />
                {t('photo.upload')}
              </>
            )}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default EnhancedPhotoUpload;