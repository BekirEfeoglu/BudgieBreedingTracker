import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useNotifications } from '@/hooks/useNotifications';

export interface PhotoItem {
  id: string;
  url: string;
  title: string;
  description?: string | undefined;
  category: 'bird' | 'chick' | 'egg' | 'breeding' | 'other';
  entityId?: string | undefined; // kuş/yavru/yumurta ID'si
  entityName?: string | undefined; // kuş/yavru/yumurta adı
  uploadDate: Date;
  tags?: string[] | undefined;
  isFavorite?: boolean | undefined;
  metadata?: {
    size?: number;
    dimensions?: { width: number; height: number };
    camera?: string;
  } | undefined;
  userId: string;
}

interface CreatePhotoInput {
  url: string;
  title: string;
  description?: string | undefined;
  category: PhotoItem['category'];
  entityId?: string | undefined;
  entityName?: string | undefined;
  tags?: string[] | undefined;
  metadata?: PhotoItem['metadata'];
}

export const usePhotoGallery = () => {
  const { user } = useAuth();
  const { addNotification } = useNotifications();
  
  const [photos, setPhotos] = useState<PhotoItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Load photos from localStorage
  const loadPhotos = useCallback(async () => {
    if (!user) {
      setPhotos([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const storageKey = `photos_${user.id}`;
      const savedPhotos = localStorage.getItem(storageKey);
      
      if (savedPhotos) {
        const parsedPhotos = JSON.parse(savedPhotos).map((photo: any) => ({
          ...photo,
          uploadDate: new Date(photo.uploadDate)
        }));
        setPhotos(parsedPhotos);
      } else {
        setPhotos([]);
      }
    } catch (err) {
      console.error('Error loading photos:', err);
      setError('Fotoğraflar yüklenirken hata oluştu');
      addNotification({
        title: 'Hata',
        message: 'Fotoğraflar yüklenirken hata oluştu',
        type: 'error'
      });
    } finally {
      setLoading(false);
    }
  }, [user, addNotification]);

  // Save photos to localStorage
  const savePhotos = useCallback((photosToSave: PhotoItem[]) => {
    if (!user) return;
    
    const storageKey = `photos_${user.id}`;
    localStorage.setItem(storageKey, JSON.stringify(photosToSave));
  }, [user]);

  // Add new photo
  const addPhoto = useCallback(async (photoInput: CreatePhotoInput): Promise<boolean> => {
    if (!user) {
      addNotification({
        title: 'Hata',
        message: 'Fotoğraf eklemek için giriş yapmalısınız',
        type: 'error'
      });
      return false;
    }

    try {
      const newPhoto: PhotoItem = {
        id: Date.now().toString() + Math.random().toString(36).substring(2),
        url: photoInput.url,
        title: photoInput.title,
        description: photoInput.description,
        category: photoInput.category,
        entityId: photoInput.entityId,
        entityName: photoInput.entityName,
        uploadDate: new Date(),
        tags: photoInput.tags || [],
        isFavorite: false,
        metadata: photoInput.metadata,
        userId: user.id
      };

      const updatedPhotos = [newPhoto, ...photos];
      setPhotos(updatedPhotos);
      savePhotos(updatedPhotos);
      
      addNotification({
        title: 'Başarılı',
        message: 'Fotoğraf başarıyla eklendi',
        type: 'info'
      });

      return true;
    } catch (err) {
      console.error('Error adding photo:', err);
      addNotification({
        title: 'Hata',
        message: 'Fotoğraf eklenirken hata oluştu',
        type: 'error'
      });
      return false;
    }
  }, [user, photos, savePhotos, addNotification]);

  // Update photo
  const updatePhoto = useCallback(async (photoId: string, updates: Partial<CreatePhotoInput>): Promise<boolean> => {
    if (!user) {
      addNotification({
        title: 'Hata',
        message: 'Fotoğraf güncellemek için giriş yapmalısınız',
        type: 'error'
      });
      return false;
    }

    try {
      const updatedPhotos = photos.map(photo => {
        if (photo.id === photoId) {
          return {
            ...photo,
            ...updates,
            tags: updates.tags || photo.tags,
            metadata: updates.metadata || photo.metadata
          };
        }
        return photo;
      });

      setPhotos(updatedPhotos);
      savePhotos(updatedPhotos);

      addNotification({
        title: 'Başarılı',
        message: 'Fotoğraf başarıyla güncellendi',
        type: 'info'
      });

      return true;
    } catch (err) {
      console.error('Error updating photo:', err);
      addNotification({
        title: 'Hata',
        message: 'Fotoğraf güncellenirken hata oluştu',
        type: 'error'
      });
      return false;
    }
  }, [user, photos, savePhotos, addNotification]);

  // Delete photo
  const deletePhoto = useCallback(async (photoId: string): Promise<boolean> => {
    if (!user) {
      addNotification({
        title: 'Hata',
        message: 'Fotoğraf silmek için giriş yapmalısınız',
        type: 'error'
      });
      return false;
    }

    try {
      const updatedPhotos = photos.filter(p => p.id !== photoId);
      setPhotos(updatedPhotos);
      savePhotos(updatedPhotos);
      
      addNotification({
        title: 'Başarılı',
        message: 'Fotoğraf başarıyla silindi',
        type: 'info'
      });

      return true;
    } catch (err) {
      console.error('Error deleting photo:', err);
      addNotification({
        title: 'Hata',
        message: 'Fotoğraf silinirken hata oluştu',
        type: 'error'
      });
      return false;
    }
  }, [user, photos, savePhotos, addNotification]);

  // Toggle favorite
  const toggleFavorite = useCallback(async (photoId: string): Promise<boolean> => {
    if (!user) {
      addNotification({
        title: 'Hata',
        message: 'Favori işlemi için giriş yapmalısınız',
        type: 'error'
      });
      return false;
    }

    try {
      const photo = photos.find(p => p.id === photoId);
      if (!photo) return false;

      const newFavoriteStatus = !photo.isFavorite;
      const updatedPhotos = photos.map(p => 
        p.id === photoId ? { ...p, isFavorite: newFavoriteStatus } : p
      );

      setPhotos(updatedPhotos);
      savePhotos(updatedPhotos);

      addNotification({
        title: newFavoriteStatus ? 'Favorilere Eklendi' : 'Favorilerden Çıkarıldı',
        message: `"${photo.title}" ${newFavoriteStatus ? 'favorilere eklendi' : 'favorilerden çıkarıldı'}`,
        type: 'info'
      });

      return true;
    } catch (err) {
      console.error('Error toggling favorite:', err);
      addNotification({
        title: 'Hata',
        message: 'Favori işlemi sırasında hata oluştu',
        type: 'error'
      });
      return false;
    }
  }, [user, photos, savePhotos, addNotification]);

  // Upload photo file (convert to base64 for now)
  const uploadPhotoFile = useCallback(async (
    file: File, 
    category: PhotoItem['category'],
    entityId?: string,
    entityName?: string
  ): Promise<string | null> => {
    if (!user) {
      addNotification({
        title: 'Hata',
        message: 'Fotoğraf yüklemek için giriş yapmalısınız',
        type: 'error'
      });
      return null;
    }

    try {
      // Validate file
      if (!file.type.startsWith('image/')) {
        throw new Error('Sadece resim dosyaları yüklenebilir');
      }

      if (file.size > 5 * 1024 * 1024) { // 5MB
        throw new Error('Dosya boyutu 5MB\'dan büyük olamaz');
      }

      // Convert to base64
      const reader = new FileReader();
      const base64Promise = new Promise<string>((resolve, reject) => {
        reader.onload = () => resolve(reader.result as string);
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });

      const base64Url = await base64Promise;

      // Get image metadata
      const img = new Image();
      const metadata = await new Promise<PhotoItem['metadata']>((resolve) => {
        img.onload = () => {
          resolve({
            size: file.size,
            dimensions: { width: img.width, height: img.height }
          });
        };
        img.onerror = () => resolve({ size: file.size });
        img.src = base64Url;
      });

      // Add to gallery
      const photoTitle = entityName ? `${entityName} Fotoğrafı` : `${category} Fotoğrafı`;
      
      await addPhoto({
        url: base64Url,
        title: photoTitle,
        category,
        entityId,
        entityName,
        metadata
      });

      return base64Url;
    } catch (err) {
      console.error('Error uploading photo:', err);
      addNotification({
        title: 'Hata',
        message: err instanceof Error ? err.message : 'Fotoğraf yüklenirken hata oluştu',
        type: 'error'
      });
      return null;
    }
  }, [user, addNotification, addPhoto]);

  // Get photos by category
  const getPhotosByCategory = useCallback((category: PhotoItem['category']) => {
    return photos.filter(photo => photo.category === category);
  }, [photos]);

  // Get photos by entity
  const getPhotosByEntity = useCallback((entityId: string) => {
    return photos.filter(photo => photo.entityId === entityId);
  }, [photos]);

  // Get favorite photos
  const getFavoritePhotos = useCallback(() => {
    return photos.filter(photo => photo.isFavorite);
  }, [photos]);

  // Get recent photos
  const getRecentPhotos = useCallback((limit = 10) => {
    return photos
      .sort((a, b) => b.uploadDate.getTime() - a.uploadDate.getTime())
      .slice(0, limit);
  }, [photos]);

  // Statistics
  const statistics = {
    total: photos.length,
    favorites: photos.filter(p => p.isFavorite).length,
    byCategory: {
      bird: photos.filter(p => p.category === 'bird').length,
      chick: photos.filter(p => p.category === 'chick').length,
      egg: photos.filter(p => p.category === 'egg').length,
      breeding: photos.filter(p => p.category === 'breeding').length,
      other: photos.filter(p => p.category === 'other').length,
    }
  };

  // Load photos when component mounts or user changes
  useEffect(() => {
    loadPhotos();
  }, [loadPhotos]);

  return {
    // Data
    photos,
    loading,
    error,
    statistics,
    
    // Actions
    addPhoto,
    updatePhoto,
    deletePhoto,
    toggleFavorite,
    uploadPhotoFile,
    loadPhotos,
    
    // Queries
    getPhotosByCategory,
    getPhotosByEntity,
    getFavoritePhotos,
    getRecentPhotos
  };
}; 