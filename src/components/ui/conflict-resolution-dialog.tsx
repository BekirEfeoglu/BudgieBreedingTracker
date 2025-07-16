import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { AlertTriangle, Clock, Database, Smartphone, CheckCircle, XCircle, RefreshCw, Merge } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';

interface ConflictResolutionDialogProps {
  isOpen: boolean;
  onClose: () => void;
  conflicts: Array<{
    id: string;
    field: string;
    localValue: string;
    remoteValue: string;
    timestamp: string;
    type: 'bird' | 'chick' | 'egg' | 'breeding';
  }>;
  onResolve: (resolution: string) => void;
}

export const ConflictResolutionDialog: React.FC<ConflictResolutionDialogProps> = ({
  isOpen,
  onClose,
  conflicts,
  onResolve
}) => {
  const getConflictIcon = (type: 'bird' | 'chick' | 'egg' | 'breeding') => {
    switch (type) {
      case 'bird':
        return '🦜';
      case 'chick':
        return '🐣';
      case 'egg':
        return '🥚';
      case 'breeding':
        return '🏠';
      default:
        return '⚠️';
    }
  };

  const getConflictDescription = (type: 'bird' | 'chick' | 'egg' | 'breeding') => {
    switch (type) {
      case 'bird':
        return 'Kuş Verisi';
      case 'chick':
        return 'Yavru Verisi';
      case 'egg':
        return 'Yumurta Verisi';
      case 'breeding':
        return 'Üreme Verisi';
      default:
        return 'Bilinmeyen Veri';
    }
  };

  const formatValue = (value: unknown): string => {
    if (value === null || value === undefined) return 'Boş';
    if (typeof value === 'object') return JSON.stringify(value, null, 2);
    if (typeof value === 'boolean') return value ? 'Evet' : 'Hayır';
    return String(value);
  };

  const handleResolve = (resolution: unknown) => {
    // Implementation of handleResolve function
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto" aria-describedby="conflict-resolution-description">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-orange-500" />
            Veri Çakışması Tespit Edildi
          </DialogTitle>
          <div id="conflict-resolution-description" className="sr-only">
            Çakışma çözümü hakkında açıklama.
          </div>
          <DialogDescription>
            {conflicts.length} kayıtta çakışma bulundu. Her çakışma için çözüm seçin veya tümü için toplu çözüm uygulayın.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Toplu Çözüm Butonları */}
          {conflicts.length > 1 && (
            <div className="flex gap-2 p-3 bg-muted/30 rounded-lg">
              <span className="text-sm font-medium">Tümü için:</span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => onResolve('local')}
              >
                Yerel Veriyi Koru
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => onResolve('remote')}
              >
                Sunucudaki Veriyi Al
              </Button>
            </div>
          )}

          {/* Çakışma Listesi */}
          <div className="space-y-4">
            {conflicts.map((conflict) => (
              <Card key={conflict.id} className="border-orange-200">
                <CardHeader className="pb-3">
                  <CardTitle className="flex items-center justify-between text-base">
                    <div className="flex items-center gap-2">
                      <span className="text-lg">{getConflictIcon(conflict.type)}</span>
                      <span>{getConflictDescription(conflict.type)}</span>
                      <Badge variant="outline">{conflict.field}</Badge>
                    </div>
                    <div className="flex items-center gap-1 text-xs text-muted-foreground">
                      <Clock className="w-3 h-3" />
                      {new Date(conflict.timestamp).toLocaleString('tr-TR')}
                    </div>
                  </CardTitle>
                </CardHeader>
                
                <CardContent className="space-y-4">
                  {/* Çakışan Alanlar */}
                  <div className="grid md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <h4 className="font-medium text-sm text-blue-700">Yerel Veri</h4>
                      <div className="bg-blue-50 p-3 rounded border text-xs">
                        <div className="flex justify-between py-1 border-b border-blue-100 last:border-0">
                          <span className="font-medium">{conflict.field}:</span>
                          <span className="text-right max-w-xs truncate">
                            {formatValue(conflict.localValue)}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <h4 className="font-medium text-sm text-green-700">Sunucu Verisi</h4>
                      <div className="bg-green-50 p-3 rounded border text-xs">
                        <div className="flex justify-between py-1 border-b border-green-100 last:border-0">
                          <span className="font-medium">{conflict.field}:</span>
                          <span className="text-right max-w-xs truncate">
                            {formatValue(conflict.remoteValue)}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Çözüm Butonları */}
                  <div className="flex gap-2 pt-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => onResolve('local')}
                      className="text-blue-700 border-blue-200 hover:bg-blue-50"
                    >
                      Yerel Veriyi Koru
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => onResolve('remote')}
                      className="text-green-700 border-green-200 hover:bg-green-50"
                    >
                      Sunucu Verisini Al
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => onResolve('merge')}
                      className="text-purple-700 border-purple-200 hover:bg-purple-50"
                    >
                      Birleştir
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Alt Bilgi */}
          <div className="text-xs text-muted-foreground bg-muted/30 p-3 rounded-lg">
            <div className="font-medium mb-1">💡 Çözüm Seçenekleri:</div>
            <ul className="space-y-1 list-disc list-inside ml-2">
              <li><strong>Yerel Veriyi Koru:</strong> Cihazınızdaki değişiklikler korunur</li>
              <li><strong>Sunucu Verisini Al:</strong> Sunucudaki güncel veri alınır</li>
              <li><strong>Birleştir:</strong> Mümkün olan alanlar birleştirilir</li>
            </ul>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};