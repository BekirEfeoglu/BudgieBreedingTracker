import React, { memo, useCallback, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Plus, Users, Egg, Heart } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import { Bird, Egg as EggType, BreedingRecord } from '@/types';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';
import { useBreedingTabLogic } from '@/hooks/breeding/useBreedingTabLogic';
import BreedingForm from '@/components/breeding/BreedingForm';
import BreedingCard from '@/components/BreedingCard';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '@/components/ui/alert-dialog';

interface BreedingTabProps {
  birds: Bird[];
  onAddEgg: (breedingId: string) => void;
  onEditEgg: (breedingId: string, egg: EggType) => void;
  onDeleteEgg: (breedingId: string, eggId: string) => void;
  onEggStatusChange: (breedingId: string, eggId: string, newStatus: string, hatchDate?: string) => void;
  isLoading?: boolean;
}

const BreedingTab = memo(({
  birds,
  onAddEgg,
  onEditEgg,
  onDeleteEgg,
  onEggStatusChange,
  isLoading = false
}: BreedingTabProps) => {
  const { t } = useLanguage();
  
  const {
    incubations,
    loading,
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

  // Sadece incubation kayıtlarını kullan
  const allBreedingRecords = useMemo((): BreedingRecord[] => {
    const incubationRecords = (incubations || []).map(inc => ({
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
    return incubationRecords.sort((a, b) => 
      new Date(b.startDate).getTime() - new Date(a.startDate).getTime()
    );
  }, [incubations, birds, t]);

  // İstatistikler
  const activeBreedingCount = useMemo(() => incubations.length, [incubations]);
  const totalEggsCount = useMemo(() => {
    // Burada eggs tablosundan sayım yapılabilir
    return 0; // Şimdilik 0 döndürüyoruz
  }, []);

  const handleDelete = useCallback((recordId: string) => {
    const record = allBreedingRecords.find(r => r.id === recordId);
    if (!record) return;
    
    if (record.type === 'incubation') {
      handleShowDeleteConfirmation(record.incubationData);
    }
  }, [allBreedingRecords, handleShowDeleteConfirmation]);

  const handleEdit = useCallback((record: BreedingRecord) => {
    if (record.type === 'incubation') {
      handleEditIncubation(record.incubationData);
    }
  }, [handleEditIncubation]);

  const handleAddEgg = useCallback((breedingId: string) => {
    onAddEgg(breedingId);
  }, [onAddEgg]);

  const handleEditEgg = useCallback((breedingId: string, egg: EggType) => {
    onEditEgg(breedingId, egg);
  }, [onEditEgg]);

  const handleDeleteEgg = useCallback((breedingId: string, eggId: string) => {
    console.log('🗑️ BreedingTab.handleDeleteEgg - Yumurta silme başlıyor:', {
      breedingId,
      eggId
    });
    onDeleteEgg(breedingId, eggId);
  }, [onDeleteEgg]);

  const handleEggStatusChange = useCallback((breedingId: string, eggId: string, newStatus: string) => {
    onEggStatusChange(breedingId, eggId, newStatus);
  }, [onEggStatusChange]);

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
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <Card className="budgie-card">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Aktif Üreme</p>
                <p className="text-2xl font-bold">{activeBreedingCount}</p>
              </div>
              <Heart className="h-8 w-8 text-pink-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="budgie-card">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Toplam Yumurta</p>
                <p className="text-2xl font-bold">{totalEggsCount}</p>
              </div>
              <Egg className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="budgie-card">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Çift Sayısı</p>
                <p className="text-2xl font-bold">{birds.filter(b => b.gender === 'male' || b.gender === 'female').length}</p>
              </div>
              <Users className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Records List */}
      {isLoading || loading ? (
        <div className="space-y-4">
          {Array.from({ length: 3 }).map((_, index) => (
            <Card key={index} className="budgie-card animate-pulse">
              <CardContent className="p-4">
                <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-1/2"></div>
              </CardContent>
            </Card>
          ))}
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
        onSave={handleIncubationFormSubmit}
        editingBreeding={editingIncubation}
        birds={birds}
      />

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={!!deleteIncubationData} onOpenChange={() => setDeleteIncubationData(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Kuluçkayı Sil</AlertDialogTitle>
            <AlertDialogDescription>
              "{deleteIncubationData?.name}" kuluçkasını silmek istediğinizden emin misiniz? 
              Bu işlem geri alınamaz ve tüm yumurta kayıtları da silinecektir.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>İptal</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (deleteIncubationData) {
                  handleDeleteIncubation(deleteIncubationData.id);
                  setDeleteIncubationData(null);
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
