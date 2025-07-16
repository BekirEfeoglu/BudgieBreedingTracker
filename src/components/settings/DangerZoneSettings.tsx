import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { AlertTriangle, Trash2, Loader2 } from 'lucide-react';
import { useDataDeletion } from '@/hooks/useDataDeletion';
import { useConfirmation } from '@/hooks/useConfirmation';
import { ConfirmationDialog } from '@/components/ui/confirmation-dialog';

const DangerZoneSettings = () => {
  const { deleteAllUserData, isDeleting } = useDataDeletion();
  const { isOpen, config, confirm, handleConfirm, handleCancel } = useConfirmation();

  const handleResetData = () => {
    confirm({
      title: 'Tüm Verileri Sil',
      description: 'Bu işlem GERİ ALINAMAZ. Tüm kuş, kuluçka, yumurta ve yavru kayıtlarınız kalıcı olarak silinecek. Devam etmek istediğinizden emin misiniz?',
      confirmText: 'Evet, Tüm Verileri Sil',
      cancelText: 'İptal',
      variant: 'destructive'
    }, async () => {
      const result = await deleteAllUserData();
      if (result.success) {
        // Force page reload to clear all local state
        setTimeout(() => {
          window.location.reload();
        }, 2000);
      }
    });
  };


  return (
    <>
      <Card className="budgie-card shadow-sm border-red-200 dark:border-red-800">
        <CardHeader className="pb-4">
          <CardTitle className="flex items-center gap-2 text-lg text-red-600 dark:text-red-400">
            <AlertTriangle className="w-5 h-5" />
            Tehlikeli Bölge
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-4">
            <Button 
              variant="destructive" 
              className="w-full justify-start min-h-[48px] text-base touch-manipulation"
              onClick={handleResetData}
              disabled={isDeleting}
            >
              {isDeleting ? (
                <>
                  <Loader2 className="w-5 h-5 mr-3 animate-spin" />
                  Siliniyor...
                </>
              ) : (
                <>
                  <Trash2 className="w-5 h-5 mr-3" />
                  Tüm Verileri Sil
                </>
              )}
            </Button>

          </div>

          <p className="text-sm text-muted-foreground bg-red-50 dark:bg-red-950/20 p-3 rounded-lg border border-red-200 dark:border-red-800">
            ⚠️ Bu işlemler geri alınamaz. Lütfen dikkatli olun.
          </p>
        </CardContent>
      </Card>

      <ConfirmationDialog
        isOpen={isOpen}
        onClose={handleCancel}
        onConfirm={handleConfirm}
        title={config.title}
        description={config.description}
        confirmText={config.confirmText}
        cancelText={config.cancelText}
        variant={config.variant}
      />
    </>
  );
};

export default DangerZoneSettings;
