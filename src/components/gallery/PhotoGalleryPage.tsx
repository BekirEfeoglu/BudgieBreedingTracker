import React, { useState, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent } from '@/components/ui/card';
import { Upload, Plus, Image as ImageIcon } from 'lucide-react';
import PhotoGallery from './PhotoGallery';
import { usePhotoGallery, PhotoItem } from '@/hooks/usePhotoGallery';
import { useIsMobile } from '@/hooks/use-mobile';

const PhotoGalleryPage: React.FC = () => {
  const isMobile = useIsMobile();
  const fileInputRef = useRef<HTMLInputElement>(null);
  
  const {
    photos,
    loading,
    statistics,
    deletePhoto,
    toggleFavorite,
    uploadPhotoFile,
    addPhoto
  } = usePhotoGallery();

  const [isUploadDialogOpen, setIsUploadDialogOpen] = useState(false);
  const [uploadForm, setUploadForm] = useState({
    title: '',
    description: '',
    category: 'other' as PhotoItem['category'],
    entityName: '',
    tags: ''
  });

  // Handle file selection
  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    await uploadPhotoFile(
      file,
      uploadForm.category,
      undefined,
      uploadForm.entityName || undefined
    );

    // Reset form
    setUploadForm({
      title: '',
      description: '',
      category: 'other',
      entityName: '',
      tags: ''
    });
    setIsUploadDialogOpen(false);
  };

  // Handle manual photo add (for demo purposes)
  const handleManualAdd = async () => {
    if (!uploadForm.title) return;

    await addPhoto({
      url: `https://picsum.photos/400/400?random=${Date.now()}`, // Demo image
      title: uploadForm.title,
      description: uploadForm.description || undefined,
      category: uploadForm.category,
      entityName: uploadForm.entityName || undefined,
      tags: uploadForm.tags ? uploadForm.tags.split(',').map(tag => tag.trim()) : undefined
    });

    // Reset form
    setUploadForm({
      title: '',
      description: '',
      category: 'other',
      entityName: '',
      tags: ''
    });
    setIsUploadDialogOpen(false);
  };

  if (loading) {
    return (
      <div className="space-y-6 p-6">
        <div className="animate-pulse">
          <div className="h-8 bg-muted rounded w-1/3 mb-4"></div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {[...Array(8)].map((_, i) => (
              <div key={i} className="aspect-square bg-muted rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      {/* Header with Statistics */}
      <div className="flex flex-col lg:flex-row gap-6">
        <div className="flex-1">
          <h1 className="text-3xl font-bold mb-2">Fotoğraf Galerisi</h1>
          <p className="text-muted-foreground">
            Kuşlarınızın, yavrularınızın ve kuluçka süreçlerinizin fotoğraflarını organize edin
          </p>
        </div>

        {/* Upload Button */}
        <div className="flex items-center gap-2">
          <Dialog open={isUploadDialogOpen} onOpenChange={setIsUploadDialogOpen}>
            <DialogTrigger asChild>
              <Button size={isMobile ? "sm" : "default"} className="gap-2">
                <Plus className="w-4 h-4" />
                Fotoğraf Ekle
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md" aria-describedby="photo-upload-description">
              <DialogHeader>
                <DialogTitle>Yeni Fotoğraf Ekle</DialogTitle>
                <DialogDescription>
                  Dosya yükleyin veya demo fotoğraf ekleyin
                </DialogDescription>
                <div id="photo-upload-description" className="sr-only">
                  Fotoğraf yükleme formu
                </div>
              </DialogHeader>
              
              <div className="space-y-4">
                {/* Title */}
                <div>
                  <Label htmlFor="title">Başlık *</Label>
                  <Input
                    id="title"
                    value={uploadForm.title}
                    onChange={(e) => setUploadForm(prev => ({ ...prev, title: e.target.value }))}
                    placeholder="Fotoğraf başlığı"
                  />
                </div>

                {/* Category */}
                <div>
                  <Label>Kategori</Label>
                  <Select 
                    value={uploadForm.category} 
                    onValueChange={(value) => setUploadForm(prev => ({ ...prev, category: value as PhotoItem['category'] }))}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="bird">🦜 Kuş</SelectItem>
                      <SelectItem value="chick">🐣 Yavru</SelectItem>
                      <SelectItem value="egg">🥚 Yumurta</SelectItem>
                      <SelectItem value="breeding">💕 Üreme</SelectItem>
                      <SelectItem value="other">📷 Diğer</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {/* Entity Name */}
                <div>
                  <Label htmlFor="entityName">İlgili Kuş/Yavru Adı</Label>
                  <Input
                    id="entityName"
                    value={uploadForm.entityName}
                    onChange={(e) => setUploadForm(prev => ({ ...prev, entityName: e.target.value }))}
                    placeholder="Opsiyonel"
                  />
                </div>

                {/* Description */}
                <div>
                  <Label htmlFor="description">Açıklama</Label>
                  <Textarea
                    id="description"
                    value={uploadForm.description}
                    onChange={(e) => setUploadForm(prev => ({ ...prev, description: e.target.value }))}
                    placeholder="Fotoğraf hakkında notlar..."
                    rows={3}
                  />
                </div>

                {/* Tags */}
                <div>
                  <Label htmlFor="tags">Etiketler</Label>
                  <Input
                    id="tags"
                    value={uploadForm.tags}
                    onChange={(e) => setUploadForm(prev => ({ ...prev, tags: e.target.value }))}
                    placeholder="Virgülle ayırın (ör: mavi, erkek, genç)"
                  />
                </div>

                {/* Action Buttons */}
                <div className="flex flex-col gap-2 pt-4">
                  <Button 
                    onClick={() => fileInputRef.current?.click()} 
                    variant="outline"
                    className="w-full"
                  >
                    <Upload className="w-4 h-4 mr-2" />
                    Dosyadan Yükle
                  </Button>
                  
                  <Button 
                    onClick={handleManualAdd}
                    disabled={!uploadForm.title}
                    className="w-full"
                  >
                    <ImageIcon className="w-4 h-4 mr-2" />
                    Demo Fotoğraf Ekle
                  </Button>
                </div>

                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleFileSelect}
                  className="hidden"
                />
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <Card>
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-primary">{statistics.total}</div>
            <div className="text-sm text-muted-foreground">Toplam</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-red-500">{statistics.favorites}</div>
            <div className="text-sm text-muted-foreground">Favori</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-blue-500">{statistics.byCategory.bird}</div>
            <div className="text-sm text-muted-foreground">🦜 Kuş</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-yellow-500">{statistics.byCategory.chick}</div>
            <div className="text-sm text-muted-foreground">🐣 Yavru</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-orange-500">{statistics.byCategory.egg}</div>
            <div className="text-sm text-muted-foreground">🥚 Yumurta</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-pink-500">{statistics.byCategory.breeding}</div>
            <div className="text-sm text-muted-foreground">💕 Üreme</div>
          </CardContent>
        </Card>
      </div>

      {/* Gallery */}
      <PhotoGallery
        photos={photos}
        onPhotoDelete={deletePhoto}
        onFavoriteToggle={toggleFavorite}
        showUploadButton={false}
      />

      {/* Empty State */}
      {photos.length === 0 && (
        <Card className="p-12 text-center">
          <div className="space-y-4">
            <div className="w-24 h-24 mx-auto bg-muted rounded-full flex items-center justify-center">
              <ImageIcon className="w-8 h-8 text-muted-foreground" />
            </div>
            <div>
              <h3 className="text-lg font-medium mb-2">Henüz fotoğraf yok</h3>
              <p className="text-muted-foreground mb-4">
                Kuşlarınızın ve kuluçka süreçlerinizin fotoğraflarını ekleyerek başlayın
              </p>
              <Button onClick={() => setIsUploadDialogOpen(true)}>
                <Plus className="w-4 h-4 mr-2" />
                İlk Fotoğrafı Ekle
              </Button>
            </div>
          </div>
        </Card>
      )}
    </div>
  );
};

export default PhotoGalleryPage; 