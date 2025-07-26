
import { useState, useCallback } from 'react';
import { useToast } from '@/hooks/use-toast';

export interface ConflictData {
  id: string;
  table: string;
  localVersion: any;
  remoteVersion: any;
  lastModified: {
    local: string;
    remote: string;
  };
  fieldConflicts?: Array<{
    field: string;
    localValue: any;
    remoteValue: any;
    severity: 'high' | 'medium' | 'low';
  }>;
  conflictScore?: number;
  autoResolvable?: boolean;
}

export interface ConflictResolution {
  conflictId: string;
  resolution: 'local' | 'remote' | 'merge';
  mergedData?: any;
}

export const useConflictResolution = () => {
  const [conflicts, setConflicts] = useState<ConflictData[]>([]);
  const [isResolvingConflict, setIsResolvingConflict] = useState(false);
  const { toast } = useToast();

  const detectConflict = useCallback((localData: any, remoteData: any, table: string) => {
    if (!localData || !remoteData) return null;

    const localModified = new Date(localData.last_modified || localData.updated_at);
    const remoteModified = new Date(remoteData.last_modified || remoteData.updated_at);
    
    // Güçlendirilmiş çatışma tespiti
    const hasVersionConflict = localData.sync_version !== remoteData.sync_version;
    const hasTimeConflict = Math.abs(localModified.getTime() - remoteModified.getTime()) > 1000;
    const isSameRecord = localData.id === remoteData.id;
    
    // Veri bütünlüğü kontrolü - field level çatışma tespiti
    const fieldConflicts = [];
    if (isSameRecord && hasVersionConflict) {
      const excludeFields = ['id', 'user_id', 'created_at', 'updated_at', 'last_modified', 'sync_version'];
      const localFields = Object.keys(localData).filter(key => !excludeFields.includes(key));
      
      for (const field of localFields) {
        if (localData[field] !== remoteData[field]) {
          fieldConflicts.push({
            field,
            localValue: localData[field],
            remoteValue: remoteData[field],
            severity: getFieldConflictSeverity(field, localData[field], remoteData[field])
          });
        }
      }
    }
    
    if (isSameRecord && (hasVersionConflict || hasTimeConflict) && fieldConflicts.length > 0) {
      return {
        id: localData.id,
        table,
        localVersion: localData,
        remoteVersion: remoteData,
        lastModified: {
          local: localModified.toISOString(),
          remote: remoteModified.toISOString()
        },
        fieldConflicts,
        conflictScore: calculateConflictScore(fieldConflicts),
        autoResolvable: isAutoResolvable(fieldConflicts)
      };
    }

    return null;
  }, []);

  const getFieldConflictSeverity = (field: string, localValue: any, remoteValue: any) => {
    // Kritik alanlar (yüksek öncelik)
    const criticalFields = ['name', 'hatch_date', 'birth_date', 'status'];
    if (criticalFields.includes(field)) return 'high';
    
    // Orta öncelikli alanlar
    const mediumFields = ['color', 'gender', 'ring_number', 'notes'];
    if (mediumFields.includes(field)) return 'medium';
    
    // Düşük öncelikli alanlar
    return 'low';
  };

  const calculateConflictScore = (fieldConflicts: any[]) => {
    return fieldConflicts.reduce((score, conflict) => {
      switch (conflict.severity) {
        case 'high': return score + 3;
        case 'medium': return score + 2;
        case 'low': return score + 1;
        default: return score;
      }
    }, 0);
  };

  const isAutoResolvable = (fieldConflicts: any[]) => {
    // Sadece düşük öncelikli alanlar çakışıyorsa otomatik çözülebilir
    return fieldConflicts.every(conflict => conflict.severity === 'low');
  };

  const addConflict = useCallback((conflictData: ConflictData) => {
    setConflicts(prev => [...prev.filter(c => c.id !== conflictData.id), conflictData]);
    
    toast({
      title: 'Veri Çatışması Tespit Edildi',
      description: `${conflictData.table} tablosunda çatışma var. Lütfen çözüm seçin.`,
      variant: 'destructive'
    });
  }, [toast]);

  const resolveConflict = useCallback(async (resolution: ConflictResolution) => {
    setIsResolvingConflict(true);
    
    try {
      const conflict = conflicts.find(c => c.id === resolution.conflictId);
      if (!conflict) throw new Error('Çatışma bulunamadı');

      let finalData;
      switch (resolution.resolution) {
        case 'local':
          finalData = conflict.localVersion;
          break;
        case 'remote':
          finalData = conflict.remoteVersion;
          break;
        case 'merge':
          finalData = resolution.mergedData || conflict.remoteVersion;
          break;
      }

      // Çatışmayı çözüldü olarak işaretle
      setConflicts(prev => prev.filter(c => c.id !== resolution.conflictId));
      
      toast({
        title: 'Çatışma Çözüldü',
        description: `${conflict.table} kaydı başarıyla güncellendi.`,
      });

      return finalData;
    } catch (error) {
      console.error('Çatışma çözme hatası:', error);
      toast({
        title: 'Çatışma Çözüm Hatası',
        description: 'Çatışma çözülürken bir hata oluştu.',
        variant: 'destructive'
      });
      throw error;
    } finally {
      setIsResolvingConflict(false);
    }
  }, [conflicts, toast]);

  return {
    conflicts,
    detectConflict,
    addConflict,
    resolveConflict,
    isResolvingConflict
  };
};
