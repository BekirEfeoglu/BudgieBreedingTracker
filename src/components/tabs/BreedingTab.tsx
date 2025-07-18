import React, { memo, useCallback, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Plus, Users, Egg, Heart } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Breeding, Egg as EggType, BreedingRecord } from '@/types';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import { useBreedingTabLogic } from '@/hooks/breeding/useBreedingTabLogic';
import BreedingForm from '@/components/breeding/BreedingForm';
import BreedingCard from '@/components/BreedingCard';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '@/components/ui/alert-dialog';

// EnhancedIncubationForm için uygun bird tipi
type IncubationFormBird = {
  id: string;
  name: string;
  gender: 'male' | 'female' | 'unknown';
  color?: string;
  age?: number;
};

// Lazy load heavy components - removed unused imports

interface BreedingTabProps {
  breeding: Breeding[];
  birds: Bird[];
  onAddBreeding: () => void;
  onEditBreeding: (breeding: Breeding) => void;
  onDeleteBreeding: (breedingId: string) => void;
  onAddEgg: (breedingId: string) => void;
  onEditEgg: (breedingId: string, egg: EggType) => void;
  onDeleteEgg: (breedingId: string, eggId: string) => void;
  onEggStatusChange: (breedingId: string, eggId: string, newStatus: string, hatchDate?: string) => void;
  isLoading?: boolean;
}

const BreedingTab = memo(({
  breeding,
  birds,
  onEditBreeding,
  onDeleteBreeding,
  onAddEgg,
  onEditEgg,
  onDeleteEgg,
  onEggStatusChange,
  isLoading = false
}: BreedingTabProps) => {
  const { t } = useLanguage();
  
  const {
    incubations,
    incubationDataLoading,
    isIncubationFormOpen,
    editingIncubation,
    deleteIncubationData,
    setDeleteIncubationData,
    handleAddIncubation,
    handleEditIncubation,
    handleDeleteIncubation,
    handleIncubationFormSubmit,
    handleIncubationFormCancel,
    handleShowDeleteConfirmation
  } = useBreedingTabLogic(birds);

  // Geleneksel üreme ve kuluçkaları görüntüleme için birleştir
  const allBreedingRecords = useMemo((): BreedingRecord[] => {
    const breedingRecords = breeding.map(breed => ({
      id: breed.id,
      nestName: breed.nestName || t('breeding.unknownNest'),
      maleBird: breed.maleBird || t('breeding.unknownBird'),
      femaleBird: breed.femaleBird || t('breeding.unknownBird'),
      startDate: breed.pairDate,
      eggs: (breed.eggs || []).map(egg => ({
        ...egg,
        dateAdded: egg.layDate || egg.dateAdded || '',
      })),
      type: 'breeding' as const,
      incubationData: undefined
    }));

    const incubationRecords = incubations.map(inc => ({
      id: inc.id,
      nestName: inc.name,
      maleBird: birds.find(b => b.id === inc.maleBirdId)?.name || t('breeding.unknownBird'),
      femaleBird: birds.find(b => b.id === inc.femaleBirdId)?.name || t('breeding.unknownBird'),
      startDate: inc.startDate,
      eggs: [],
      type: 'incubation' as const,
      incubationData: inc
    }));

    // Sort by start date (newest first)
    return [...breedingRecords, ...incubationRecords].sort((a, b) => 
      new Date(b.startDate).getTime() - new Date(a.startDate).getTime()
    );
  }, [breeding, incubations, birds, t]);

  // İstatistikler
  const activeBreedingCount = useMemo(() => breeding.length, [breeding]);
  const incubatingCount = useMemo(() => incubations.length, [incubations]);
  const totalEggsCount = useMemo(() => {
    const breedingEggs = breeding.reduce((total, breed) => total + (breed.eggs?.length || 0), 0);
    return breedingEggs;
  }, [breeding]);

  const handleDelete = useCallback((recordId: string) => {
    const record = allBreedingRecords.find(r => r.id === recordId);
    if (!record) return;
    
    if (record.type === 'incubation') {
      handleShowDeleteConfirmation(record.incubationData);
    } else {
      onDeleteBreeding(recordId);
    }
  }, [allBreedingRecords, handleShowDeleteConfirmation, onDeleteBreeding]);

  const handleEdit = useCallback((record: BreedingRecord) => {
    if (record.type === 'incubation') {
      handleEditIncubation(record.incubationData);
    } else {
      // Find the original breeding record
      const originalBreeding = breeding.find(b => b.id === record.id);
      if (originalBreeding) {
        onEditBreeding(originalBreeding);
      }
    }
  }, [handleEditIncubation, onEditBreeding, breeding]);

  const handleAddEgg = useCallback((breedingId: string) => {
    onAddEgg(breedingId);
  }, [onAddEgg]);

  const handleEditEgg = useCallback((breedingId: string, egg: EggType) => {
    onEditEgg(breedingId, egg);
  }, [onEditEgg]);

  const handleDeleteEgg = useCallback((breedingId: string, eggId: string) => {
    onDeleteEgg(breedingId, eggId);
  }, [onDeleteEgg]);

  const handleEggStatusChange = useCallback((breedingId: string, eggId: string, newStatus: string) => {
    onEggStatusChange(breedingId, eggId, newStatus);
  }, [onEggStatusChange]);

  const handleSaveBreeding = useCallback(async (data: Partial<Breeding>) => {
    try {
      await handleIncubationFormSubmit(data);
    } catch (error) {
      console.error('Error saving breeding:', error);
    }
  }, [handleIncubationFormSubmit]);

  // Convert Incubation to Breeding for form compatibility
  const editingBreedingForForm = useMemo(() => {
    if (!editingIncubation) return null;
    
    return {
      id: editingIncubation.id,
      maleBirdId: editingIncubation.maleBirdId,
      femaleBirdId: editingIncubation.femaleBirdId,
      pairDate: editingIncubation.startDate,
      notes: '',
      nestName: editingIncubation.name,
      maleBird: birds.find(b => b.id === editingIncubation.maleBirdId)?.name || '',
      femaleBird: birds.find(b => b.id === editingIncubation.femaleBirdId)?.name || '',
      eggs: []
    } as Breeding;
  }, [editingIncubation, birds]);

  const isLoadingState = isLoading || incubationDataLoading;
  const hasRecords = allBreedingRecords.length > 0;

  return (
    <div className="space-y-4 sm:space-y-6 pb-20 md:pb-4 px-2 md:px-0 min-w-0" role="region" aria-label="Üreme">
      {/* Header */}
      <div className="mobile-header min-w-0">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 min-w-0">
          <div className="min-w-0 flex-1">
            <h1 className="mobile-header-title truncate max-w-full min-w-0">Üreme Yönetimi</h1>
            <p className="mobile-subtitle truncate max-w-full min-w-0">
              Üreme çiftlerini ve kuluçka süreçlerini takip edin
            </p>
          </div>
          
          <div className="mobile-header-actions min-w-0 flex-shrink-0">
            <Button 
              onClick={handleAddIncubation}
              className="w-full sm:w-auto enhanced-button-primary mobile-form-button min-w-0"
            >
              <Plus className="w-4 h-4 mr-2 flex-shrink-0" />
              <span className="truncate max-w-full min-w-0">Üreme Ekle</span>
            </Button>
          </div>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="mobile-grid mobile-grid-cols-3 gap-4 min-w-0">
        <Card className="mobile-card min-w-0">
          <CardContent className="p-4 min-w-0">
            <div className="flex items-center gap-3 min-w-0">
              <div className="p-2 bg-primary/10 rounded-full flex-shrink-0">
                <Users className="w-4 h-4 text-primary flex-shrink-0" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">Aktif Çiftler</p>
                <p className="text-xl font-bold truncate max-w-full min-w-0">{activeBreedingCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="mobile-card min-w-0">
          <CardContent className="p-4 min-w-0">
            <div className="flex items-center gap-3 min-w-0">
              <div className="p-2 bg-orange-100 rounded-full flex-shrink-0">
                <Egg className="w-4 h-4 text-orange-600 flex-shrink-0" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">Kuluçkada</p>
                <p className="text-xl font-bold truncate max-w-full min-w-0">{incubatingCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="mobile-card min-w-0">
          <CardContent className="p-4 min-w-0">
            <div className="flex items-center gap-3 min-w-0">
              <div className="p-2 bg-green-100 rounded-full flex-shrink-0">
                <Egg className="w-4 h-4 text-green-600 flex-shrink-0" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm text-muted-foreground truncate max-w-full min-w-0">Toplam Yumurta</p>
                <p className="text-xl font-bold truncate max-w-full min-w-0">{totalEggsCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Content */}
      {isLoadingState ? (
        <div className="mobile-empty-state min-w-0" role="status" aria-label="Yükleniyor">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto flex-shrink-0"></div>
          <p className="mobile-empty-text truncate max-w-full min-w-0">Yükleniyor...</p>
        </div>
      ) : !hasRecords ? (
        <div className="mobile-empty-state min-w-0" role="status" aria-label="Üreme kaydı bulunamadı">
          <Heart className="h-12 w-12 mx-auto mb-4 opacity-50 flex-shrink-0" />
          <p className="mobile-empty-text truncate max-w-full min-w-0">Henüz üreme kaydı bulunmuyor</p>
          <Button 
            onClick={handleAddIncubation}
            className="mt-4 enhanced-button-primary mobile-form-button min-w-0"
          >
            <Plus className="w-4 h-4 mr-2 flex-shrink-0" />
            <span className="truncate max-w-full min-w-0">İlk Üremeyi Ekle</span>
          </Button>
        </div>
      ) : (
        <div className="space-y-4 min-w-0">
          {allBreedingRecords.map((record) => (
            <BreedingCard
              key={record.id}
              breeding={record}
              onEdit={handleEdit}
              onAddEgg={handleAddEgg}
              onEditEgg={handleEditEgg}
              onDeleteEgg={handleDeleteEgg}
              onDelete={handleDelete}
              onEggStatusChange={handleEggStatusChange}
            />
          ))}
        </div>
      )}

      {/* Breeding Form Modal */}
      <BreedingForm
        isOpen={isIncubationFormOpen}
        onClose={handleIncubationFormCancel}
        onSave={handleSaveBreeding}
        editingBreeding={editingBreedingForForm}
        birds={birds}
      />

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={!!deleteIncubationData} onOpenChange={() => setDeleteIncubationData(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Kuluçka Sil</AlertDialogTitle>
            <AlertDialogDescription>
              "{deleteIncubationData?.name}" kuluçkasını silmek istediğinizden emin misiniz? 
              Bu işlem geri alınamaz.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>İptal</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (deleteIncubationData) {
                  handleDeleteIncubation(deleteIncubationData.id);
                }
              }}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Sil
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
});

BreedingTab.displayName = 'BreedingTab';

export default BreedingTab;
