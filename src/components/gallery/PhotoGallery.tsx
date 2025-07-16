import React, { useState, useCallback, useMemo } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { 
  Search, 
  Grid3X3, 
  List, 
  Download, 
  Trash2, 
  Eye, 
  Calendar,
  Image as ImageIcon,
  Upload
} from 'lucide-react';

interface Photo {
  id: string;
  url: string;
  title: string;
  description?: string;
  tags: string[];
  dateAdded: string;
  size: number;
  type: string;
}

interface PhotoGalleryProps {
  photos: Photo[];
  onPhotoSelect?: (photo: Photo) => void;
  onPhotoDelete?: (photoId: string) => void;
  onPhotoDownload?: (photo: Photo) => void;
  allowSelection?: boolean;
  allowDeletion?: boolean;
  allowDownload?: boolean;
}

const PhotoGallery: React.FC<PhotoGalleryProps> = ({
  photos,
  onPhotoSelect,
  onPhotoDelete,
  onPhotoDownload,
  allowSelection = true,
  allowDeletion = true,
  allowDownload = true
}) => {
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedFilter, setSelectedFilter] = useState<string>('all');
  const [selectedPhoto, setSelectedPhoto] = useState<Photo | null>(null);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);

  const filteredPhotos = useMemo(() => {
    return photos.filter(photo => {
      const matchesSearch = photo.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           photo.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           photo.tags.some(tag => tag.toLowerCase().includes(searchTerm.toLowerCase()));
      
      const matchesFilter = selectedFilter === 'all' || photo.tags.includes(selectedFilter);
      
      return matchesSearch && matchesFilter;
    });
  }, [photos, searchTerm, selectedFilter]);

  const availableTags = useMemo(() => {
    const tags = new Set<string>();
    photos.forEach(photo => {
      photo.tags.forEach(tag => tags.add(tag));
    });
    return Array.from(tags);
  }, [photos]);

  const handlePhotoClick = useCallback((photo: Photo) => {
    if (allowSelection && onPhotoSelect) {
      onPhotoSelect(photo);
    } else {
      setSelectedPhoto(photo);
      setIsDetailModalOpen(true);
    }
  }, [allowSelection, onPhotoSelect]);

  const handleDelete = useCallback((photoId: string) => {
    if (onPhotoDelete) {
      onPhotoDelete(photoId);
    }
  }, [onPhotoDelete]);

  const handleDownload = useCallback((photo: Photo) => {
    if (onPhotoDownload) {
      onPhotoDownload(photo);
    }
  }, [onPhotoDownload]);

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatDate = (dateString: string): string => {
    return new Date(dateString).toLocaleDateString('tr-TR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Fotoğraf Galerisi</h2>
          <p className="text-muted-foreground">
            {filteredPhotos.length} fotoğraf bulundu
          </p>
        </div>
        
        <div className="flex gap-2">
          <Button
            variant={viewMode === 'grid' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('grid')}
          >
            <Grid3X3 className="w-4 h-4" />
          </Button>
          <Button
            variant={viewMode === 'list' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('list')}
          >
            <List className="w-4 h-4" />
          </Button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4" />
          <Input
            placeholder="Fotoğraf ara..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        
        <Select value={selectedFilter} onValueChange={setSelectedFilter}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="Etiket seç" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tümü</SelectItem>
            {availableTags.map(tag => (
              <SelectItem key={tag} value={tag}>{tag}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Photo Grid/List */}
      {viewMode === 'grid' ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {filteredPhotos.map((photo) => (
            <Card
              key={photo.id}
              className="group cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => handlePhotoClick(photo)}
            >
              <div className="relative aspect-square overflow-hidden rounded-t-lg">
                <img
                  src={photo.url}
                  alt={photo.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
                />
                
                {/* Overlay Actions */}
                <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                  <Button
                    size="sm"
                    variant="secondary"
                    onClick={(_e) => handlePhotoClick(photo)}
                  >
                    <Eye className="w-4 h-4" />
                  </Button>
                  
                  {allowDownload && onPhotoDownload && (
                    <Button
                      size="sm"
                      variant="secondary"
                      onClick={(_e) => handleDownload(photo)}
                    >
                      <Download className="w-4 h-4" />
                    </Button>
                  )}
                  
                  {allowDeletion && onPhotoDelete && (
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={(_e) => handleDelete(photo.id)}
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  )}
                </div>
              </div>
              
              <CardContent className="p-3">
                <h3 className="font-medium text-sm truncate">{photo.title}</h3>
                <div className="flex items-center gap-2 mt-1">
                  <Calendar className="w-3 h-3 text-muted-foreground" />
                  <span className="text-xs text-muted-foreground">
                    {formatDate(photo.dateAdded)}
                  </span>
                </div>
                <div className="flex flex-wrap gap-1 mt-2">
                  {photo.tags.slice(0, 2).map(tag => (
                    <Badge key={tag} variant="secondary" className="text-xs">
                      {tag}
                    </Badge>
                  ))}
                  {photo.tags.length > 2 && (
                    <Badge variant="outline" className="text-xs">
                      +{photo.tags.length - 2}
                    </Badge>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <div className="space-y-2">
          {filteredPhotos.map((photo) => (
            <Card
              key={photo.id}
              className="group cursor-pointer hover:shadow-md transition-shadow"
              onClick={() => handlePhotoClick(photo)}
            >
              <CardContent className="p-4">
                <div className="flex items-center gap-4">
                  <div className="relative w-16 h-16 flex-shrink-0">
                    <img
                      src={photo.url}
                      alt={photo.title}
                      className="w-full h-full object-cover rounded"
                    />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <h3 className="font-medium truncate">{photo.title}</h3>
                    {photo.description && (
                      <p className="text-sm text-muted-foreground truncate">
                        {photo.description}
                      </p>
                    )}
                    <div className="flex items-center gap-4 mt-1 text-xs text-muted-foreground">
                      <span className="flex items-center gap-1">
                        <Calendar className="w-3 h-3" />
                        {formatDate(photo.dateAdded)}
                      </span>
                      <span>{formatFileSize(photo.size)}</span>
                      <span>{photo.type}</span>
                    </div>
                    <div className="flex flex-wrap gap-1 mt-2">
                      {photo.tags.map(tag => (
                        <Badge key={tag} variant="secondary" className="text-xs">
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  </div>
                  
                  <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={(_e) => handlePhotoClick(photo)}
                    >
                      <Eye className="w-4 h-4" />
                    </Button>
                    
                    {allowDownload && onPhotoDownload && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={(_e) => handleDownload(photo)}
                      >
                        <Download className="w-4 h-4" />
                      </Button>
                    )}
                    
                    {allowDeletion && onPhotoDelete && (
                      <Button
                        size="sm"
                        variant="destructive"
                        onClick={(_e) => handleDelete(photo.id)}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Empty State */}
      {filteredPhotos.length === 0 && (
        <div className="text-center py-12">
          <ImageIcon className="w-12 h-12 mx-auto text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium mb-2">Fotoğraf bulunamadı</h3>
          <p className="text-muted-foreground mb-4">
            Arama kriterlerinize uygun fotoğraf bulunamadı.
          </p>
          <Button variant="outline">
            <Upload className="w-4 h-4 mr-2" />
            Fotoğraf Yükle
          </Button>
        </div>
      )}

      {/* Photo Detail Modal */}
      <Dialog open={isDetailModalOpen} onOpenChange={setIsDetailModalOpen}>
        <DialogContent className="max-w-2xl" aria-describedby="photo-detail-description">
          <DialogHeader>
            <DialogTitle>{selectedPhoto?.title}</DialogTitle>
            <div id="photo-detail-description" className="sr-only">
              {selectedPhoto?.title} fotoğraf detayları
            </div>
          </DialogHeader>
          
          {selectedPhoto && (
            <div className="space-y-4">
              <div className="relative aspect-video overflow-hidden rounded-lg">
                <img
                  src={selectedPhoto.url}
                  alt={selectedPhoto.title}
                  className="w-full h-full object-cover"
                />
              </div>
              
              <div className="space-y-2">
                {selectedPhoto.description && (
                  <p className="text-muted-foreground">
                    {selectedPhoto.description}
                  </p>
                )}
                
                <div className="flex items-center gap-4 text-sm text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <Calendar className="w-4 h-4" />
                    {formatDate(selectedPhoto.dateAdded)}
                  </span>
                  <span>{formatFileSize(selectedPhoto.size)}</span>
                  <span>{selectedPhoto.type}</span>
                </div>
                
                <div className="flex flex-wrap gap-1">
                  {selectedPhoto.tags.map(tag => (
                    <Badge key={tag} variant="secondary">
                      {tag}
                    </Badge>
                  ))}
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default PhotoGallery; 