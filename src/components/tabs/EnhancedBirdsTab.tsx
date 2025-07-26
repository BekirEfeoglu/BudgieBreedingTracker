import React, { useState, Suspense } from 'react';
import { Plus, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import BirdCard from '@/components/BirdCard';
import BirdDetailModal from '@/components/BirdDetailModal';
import AdvancedFilters from '@/components/filters/AdvancedFilters';
import { useAdvancedFilters } from '@/hooks/useAdvancedFilters';
import { useIsMobile } from '@/hooks/use-mobile';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird } from '@/types';

interface EnhancedBirdsTabProps {
  birds: Bird[];
  loading: boolean;
  onAddBird: () => void;
  onEditBird: (bird: Bird) => void;
  onDeleteBird: (birdId: string) => void;
  error?: string;
}

const EnhancedBirdsTab: React.FC<EnhancedBirdsTabProps> = ({
  birds,
  loading,
  onAddBird,
  onEditBird,
  onDeleteBird,
  error
}) => {
  const { t: _t } = useLanguage();
  const isMobile = useIsMobile();
  
  const [selectedBird, setSelectedBird] = useState<Bird | null>(null);
  const [isDetailModalOpen, setIsDetailModalOpen] = useState(false);

  // Use advanced filters hook
  const {
    filteredItems: filteredBirds,
    activeFilterCount,
    filterSummary,
    resetFilters
  } = useAdvancedFilters(birds, 'birds');

  // Bird action handlers
  const handleViewBirdDetails = (bird: Bird) => {
    setSelectedBird(bird);
    setIsDetailModalOpen(true);
  };

  const handleCloseDetailModal = () => {
    setIsDetailModalOpen(false);
    setSelectedBird(null);
  };

  const handleEditFromModal = (bird: Bird) => {
    setIsDetailModalOpen(false);
    setSelectedBird(null);
    onEditBird(bird);
  };

  const handleDeleteFromModal = (birdId: string) => {
    onDeleteBird(birdId);
    setIsDetailModalOpen(false);
    setSelectedBird(null);
  };

  // Enhanced filter change handler
  const handleFiltersChange = (_filters: any) => {
    // The hook already handles this internally
    // This is mainly for external components that need to react to filter changes
  };

  if (loading) {
    return (
      <div className="mobile-spacing-y mobile-container">
        <div className="text-center py-8">
          <Loader2 className="w-8 h-8 animate-spin mx-auto mb-4 text-primary" />
          <p className="text-muted-foreground">Kuşlar yükleniyor...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="mobile-spacing-y mobile-container">
        <Alert variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      </div>
    );
  }

  return (
    <div className="mobile-spacing-y mobile-container">
      {/* Header */}
      <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold mb-2">Kuşlarım</h2>
          <div className="flex items-center gap-4">
            <p className="text-muted-foreground">
              {filterSummary.total} kuş, {filterSummary.filtered} gösteriliyor
            </p>
            {activeFilterCount > 0 && (
              <Badge variant="secondary" className="gap-1">
                {activeFilterCount} filtre aktif
              </Badge>
            )}
            {filterSummary.percentage < 100 && (
              <Badge variant="outline" className="text-orange-600">
                %{filterSummary.percentage} gösteriliyor
              </Badge>
            )}
          </div>
        </div>

        <Button 
          onClick={onAddBird}
          className="gap-2 w-full lg:w-auto"
          size={isMobile ? "default" : "default"}
        >
          <Plus className="w-5 h-5" />
          Kuş Ekle
        </Button>
      </div>

      {/* Advanced Filters */}
      <AdvancedFilters
        filters={{} as any}
        onFiltersChange={handleFiltersChange}
        onReset={() => {}}
      />

      {/* Filter Summary */}
      {activeFilterCount > 0 && (
        <div className="bg-muted/50 rounded-lg p-4">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
            <div className="space-y-1">
              <h3 className="font-medium text-sm">Filtre Sonuçları</h3>
              <p className="text-xs text-muted-foreground">
                {filterSummary.filtered} kuş görüntüleniyor ({filterSummary.total} toplam)
              </p>
              {filterSummary.hidden > 0 && (
                <p className="text-xs text-orange-600">
                  {filterSummary.hidden} kuş filtreler nedeniyle gizlendi
                </p>
              )}
            </div>
            <Button variant="outline" size="sm" onClick={resetFilters}>
              Filtreleri Temizle
            </Button>
          </div>
        </div>
      )}

      {/* Birds Grid */}
      {filteredBirds.length === 0 ? (
        <div className="text-center py-12">
          <div className="w-24 h-24 mx-auto mb-4 bg-muted rounded-full flex items-center justify-center">
            <span className="text-4xl">🦜</span>
          </div>
          {birds.length === 0 ? (
            <>
              <h3 className="text-lg font-medium mb-2">Henüz kuş eklenmemiş</h3>
              <p className="text-muted-foreground mb-4">
                İlk kuşunuzu eklemek için "Kuş Ekle" butonuna tıklayın.
              </p>
              <Button onClick={onAddBird} className="gap-2">
                <Plus className="w-4 h-4" />
                İlk Kuşu Ekle
              </Button>
            </>
          ) : (
            <>
              <h3 className="text-lg font-medium mb-2">Filtre kriterlerinize uygun kuş bulunamadı</h3>
              <p className="text-muted-foreground mb-4">
                Lütfen filtre ayarlarınızı değiştirin veya temizleyin.
              </p>
              <div className="flex flex-col sm:flex-row gap-2 justify-center">
                <Button variant="outline" onClick={resetFilters}>
                  Filtreleri Temizle
                </Button>
                <Button onClick={onAddBird} className="gap-2">
                  <Plus className="w-4 h-4" />
                  Yeni Kuş Ekle
                </Button>
              </div>
            </>
          )}
        </div>
      ) : (
        <>
          {/* Results info */}
          <div className="flex items-center justify-between text-sm text-muted-foreground">
            <span>
              {filteredBirds.length} sonuç 
              {activeFilterCount > 0 && ` (${birds.length} toplam)`}
            </span>
            {filteredBirds.length > 20 && (
              <span>
                Grid görünümde en iyi performans için büyük listeler filtrelenmeli
              </span>
            )}
          </div>

          {/* Birds Grid */}
          <div className={`grid gap-4 ${
            isMobile 
              ? 'grid-cols-1' 
              : 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
          }`}>
            {filteredBirds.map((bird) => (
              <BirdCard
                key={bird.id}
                bird={bird}
                birds={birds} // Pass all birds for parent name lookup
                onEdit={onEditBird}
                onDelete={onDeleteBird}
                onViewDetails={handleViewBirdDetails}
              />
            ))}
          </div>

          {/* Load more indicator for large lists */}
          {filteredBirds.length > 50 && (
            <div className="text-center py-4">
              <Badge variant="outline" className="text-muted-foreground">
                {filteredBirds.length} kuş gösteriliyor
              </Badge>
            </div>
          )}
        </>
      )}

      {/* Bird Detail Modal */}
      <Suspense fallback={<div>Modal yükleniyor...</div>}>
        <BirdDetailModal
          bird={selectedBird}
          isOpen={isDetailModalOpen}
          onClose={handleCloseDetailModal}
          onEdit={handleEditFromModal}
          onDelete={handleDeleteFromModal}
          existingBirds={birds}
        />
      </Suspense>
    </div>
  );
};

export default EnhancedBirdsTab; 