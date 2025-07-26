import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { AlertTriangle, Trash2, Loader2 } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/useAuth';

const DangerZoneSettings = () => {
  const { toast } = useToast();
  const { user } = useAuth();
  const [isDeleting, setIsDeleting] = useState(false);
  const [showConfirmation, setShowConfirmation] = useState(false);

  const handleDeleteAccount = async () => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı bilgisi bulunamadı',
        variant: 'destructive',
      });
      return;
    }

    setIsDeleting(true);
    try {
      // Mock account deletion
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      toast({
        title: 'Hesap Silindi',
        description: 'Hesabınız başarıyla silindi',
      });
      
      // Redirect to login or home page
      window.location.href = '/';
    } catch (error) {
      console.error('Account deletion error:', error);
      toast({
        title: 'Hata',
        description: 'Hesap silinirken bir hata oluştu',
        variant: 'destructive',
      });
    } finally {
      setIsDeleting(false);
      setShowConfirmation(false);
    }
  };

  const handleDeleteAllData = async () => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı bilgisi bulunamadı',
        variant: 'destructive',
      });
      return;
    }

    setIsDeleting(true);
    try {
      // Mock data deletion
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      toast({
        title: 'Veriler Silindi',
        description: 'Tüm verileriniz başarıyla silindi',
      });
    } catch (error) {
      console.error('Data deletion error:', error);
      toast({
        title: 'Hata',
        description: 'Veriler silinirken bir hata oluştu',
        variant: 'destructive',
      });
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className="space-y-6">
      <Card className="border-red-200 bg-red-50">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-red-800">
            <AlertTriangle className="h-5 w-5" />
            Tehlikeli Bölge
          </CardTitle>
          <CardDescription className="text-red-700">
            Bu işlemler geri alınamaz. Dikkatli olun.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Tüm Verileri Sil */}
          <div className="space-y-4">
            <div>
              <h3 className="font-semibold text-red-800">Tüm Verileri Sil</h3>
              <p className="text-sm text-red-700">
                Kuşlarınız, üretim kayıtlarınız, yumurtalarınız ve tüm verileriniz kalıcı olarak silinecek.
              </p>
            </div>
            <Button
              variant="outline"
              onClick={handleDeleteAllData}
              disabled={isDeleting}
              className="border-red-300 text-red-700 hover:bg-red-100"
            >
              {isDeleting ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Siliniyor...
                </>
              ) : (
                <>
                  <Trash2 className="h-4 w-4 mr-2" />
                  Tüm Verileri Sil
                </>
              )}
            </Button>
          </div>

          <div className="border-t border-red-200 pt-6">
            <div className="space-y-4">
              <div>
                <h3 className="font-semibold text-red-800">Hesabı Sil</h3>
                <p className="text-sm text-red-700">
                  Hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz.
                </p>
              </div>
              
              {!showConfirmation ? (
                <Button
                  variant="destructive"
                  onClick={() => setShowConfirmation(true)}
                  disabled={isDeleting}
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  Hesabı Sil
                </Button>
              ) : (
                <div className="space-y-3">
                  <div className="p-4 bg-red-100 border border-red-300 rounded-lg">
                    <p className="text-sm text-red-800 font-medium">
                      Bu işlem geri alınamaz! Hesabınızı silmek istediğinizden emin misiniz?
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <Button
                      variant="destructive"
                      onClick={handleDeleteAccount}
                      disabled={isDeleting}
                    >
                      {isDeleting ? (
                        <>
                          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                          Siliniyor...
                        </>
                      ) : (
                        <>
                          <Trash2 className="h-4 w-4 mr-2" />
                          Evet, Hesabımı Sil
                        </>
                      )}
                    </Button>
                    <Button
                      variant="outline"
                      onClick={() => setShowConfirmation(false)}
                      disabled={isDeleting}
                    >
                      İptal
                    </Button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default DangerZoneSettings;
