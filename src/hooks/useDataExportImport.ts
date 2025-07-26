import { useState, useCallback } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useNotifications } from '@/hooks/useNotifications';

interface ExportData {
  birds?: any[];
  chicks?: any[];
  breeding?: any[];
  eggs?: any[];
  incubations?: any[];
  metadata?: {
    exportDate: string;
    version: string;
    userId: string;
    totalRecords: number;
  };
}

interface ImportStats {
  totalProcessed: number;
  successfullyImported: number;
  errors: number;
  warnings: string[];
}

export const useDataExportImport = () => {
  const { user } = useAuth();
  const { addNotification } = useNotifications();
  
  const [isExporting, setIsExporting] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [exportProgress, setExportProgress] = useState(0);
  const [importProgress, setImportProgress] = useState(0);

  // Generate export data
  const prepareExportData = useCallback((data: ExportData): ExportData => {
    const exportData: ExportData = {
      metadata: {
        exportDate: new Date().toISOString(),
        version: '1.0.0',
        userId: user?.id || 'unknown',
        totalRecords: 0
      }
    };

    // Add each data type if provided
    if (data.birds && data.birds.length > 0) {
      exportData.birds = data.birds.map(bird => ({
        ...bird,
        // Remove sensitive fields if needed
        id: undefined, // Will be regenerated on import
        userId: undefined,
        createdAt: bird.createdAt || new Date().toISOString(),
        updatedAt: bird.updatedAt || new Date().toISOString()
      }));
      if (exportData.metadata) {
        exportData.metadata.totalRecords += data.birds.length;
      }
    }

    if (data.chicks && data.chicks.length > 0) {
      exportData.chicks = data.chicks.map(chick => ({
        ...chick,
        id: undefined,
        userId: undefined,
        createdAt: chick.createdAt || new Date().toISOString(),
        updatedAt: chick.updatedAt || new Date().toISOString()
      }));
             if (exportData.metadata) {
         exportData.metadata.totalRecords += data.chicks.length;
       }
     }

     if (data.breeding && data.breeding.length > 0) {
       exportData.breeding = data.breeding.map(breed => ({
         ...breed,
         id: undefined,
         userId: undefined,
         createdAt: breed.createdAt || new Date().toISOString(),
         updatedAt: breed.updatedAt || new Date().toISOString()
       }));
       if (exportData.metadata) {
         exportData.metadata.totalRecords += data.breeding.length;
       }
     }

     if (data.eggs && data.eggs.length > 0) {
       exportData.eggs = data.eggs.map(egg => ({
         ...egg,
         id: undefined,
         userId: undefined,
         createdAt: egg.createdAt || new Date().toISOString(),
         updatedAt: egg.updatedAt || new Date().toISOString()
       }));
       if (exportData.metadata) {
         exportData.metadata.totalRecords += data.eggs.length;
       }
    }

    if (data.incubations && data.incubations.length > 0) {
      exportData.incubations = data.incubations.map(incubation => ({
        ...incubation,
        id: undefined,
        userId: undefined,
        createdAt: incubation.createdAt || new Date().toISOString(),
        updatedAt: incubation.updatedAt || new Date().toISOString()
      }));
             if (exportData.metadata) {
         exportData.metadata.totalRecords += data.incubations.length;
       }
    }

    return exportData;
  }, [user]);

  // Export to JSON
  const exportToJSON = useCallback(async (data: ExportData, filename?: string): Promise<boolean> => {
    if (!user) {
      addNotification({
        title: 'Hata',
        message: 'Dışa aktarım için giriş yapmalısınız.',
        type: 'error'
      });
      return false;
    }

    setIsExporting(true);
    setExportProgress(0);

    try {
      const exportData = prepareExportData(data);
      setExportProgress(30);

      const jsonString = JSON.stringify(exportData, null, 2);
      setExportProgress(60);

      const blob = new Blob([jsonString], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      
      const defaultFilename = `budgie-data-${new Date().toISOString().split('T')[0]}.json`;
      const link = document.createElement('a');
      link.href = url;
      link.download = filename || defaultFilename;
      
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      URL.revokeObjectURL(url);
      setExportProgress(100);

      addNotification({
        title: 'Başarılı',
        message: `${exportData.metadata?.totalRecords || 0} kayıt JSON formatında dışa aktarıldı.`,
        type: 'info'
      });

      return true;
    } catch (error) {
      console.error('JSON export error:', error);
      addNotification({
        title: 'Hata',
        message: 'JSON dışa aktarımı sırasında hata oluştu.',
        type: 'error'
      });
      return false;
    } finally {
      setIsExporting(false);
      setTimeout(() => setExportProgress(0), 1000);
    }
  }, [user, prepareExportData, addNotification]);

  // Export to CSV
  const exportToCSV = useCallback(async (data: ExportData, filename?: string): Promise<boolean> => {
    if (!user) {
      addNotification({
        title: 'Hata',
        message: 'Dışa aktarım için giriş yapmalısınız.',
        type: 'error'
      });
      return false;
    }

    setIsExporting(true);
    setExportProgress(0);

    try {
      const exportData = prepareExportData(data);
      setExportProgress(20);

      let csvContent = '';
      let totalRecords = 0;

      // Helper function to convert array to CSV
      const arrayToCSV = (array: any[], title: string): string => {
        if (!array || array.length === 0) return '';
        
        const headers = Object.keys(array[0]);
        const csvHeaders = headers.join(',');
        
        const csvRows = array.map(item => {
          return headers.map(header => {
            let value = item[header] || '';
            // Handle special characters in CSV
            if (typeof value === 'string') {
              value = value.replace(/"/g, '""');
              if (value.includes(',') || value.includes('\n') || value.includes('"')) {
                value = `"${value}"`;
              }
            }
            return value;
          }).join(',');
        });

        return `# ${title}\n${csvHeaders}\n${csvRows.join('\n')}\n\n`;
      };

      // Add each data type to CSV
      if (exportData.birds) {
        csvContent += arrayToCSV(exportData.birds, 'KUŞLAR (BIRDS)');
        totalRecords += exportData.birds.length;
        setExportProgress(40);
      }

      if (exportData.chicks) {
        csvContent += arrayToCSV(exportData.chicks, 'YAVRULAR (CHICKS)');
        totalRecords += exportData.chicks.length;
        setExportProgress(50);
      }

      if (exportData.breeding) {
        csvContent += arrayToCSV(exportData.breeding, 'ÜREME (BREEDING)');
        totalRecords += exportData.breeding.length;
        setExportProgress(60);
      }

      if (exportData.eggs) {
        csvContent += arrayToCSV(exportData.eggs, 'YUMURTALAR (EGGS)');
        totalRecords += exportData.eggs.length;
        setExportProgress(70);
      }

      if (exportData.incubations) {
        csvContent += arrayToCSV(exportData.incubations, 'KULUÇKA (INCUBATIONS)');
        totalRecords += exportData.incubations.length;
        setExportProgress(80);
      }

      // Add metadata header
      const metadataHeader = `# BUDGIEBREEDINGTRACKER VERİLERİ
# Export Date: ${exportData.metadata?.exportDate}
# Version: ${exportData.metadata?.version}
# Total Records: ${totalRecords}
# 
# Bu dosya BudgieBreedingTracker uygulamasından dışa aktarılmıştır.
# Verileri geri yüklemek için uygulamanın içe aktarım özelliğini kullanın.

`;

      csvContent = metadataHeader + csvContent;
      setExportProgress(90);

      // Add BOM for proper Turkish character support
      const csvWithBOM = '\uFEFF' + csvContent;
      const blob = new Blob([csvWithBOM], { type: 'text/csv;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      
      const defaultFilename = `budgie-data-${new Date().toISOString().split('T')[0]}.csv`;
      const link = document.createElement('a');
      link.href = url;
      link.download = filename || defaultFilename;
      
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      URL.revokeObjectURL(url);
      setExportProgress(100);

      addNotification({
        title: 'Başarılı',
        message: `${totalRecords} kayıt CSV formatında dışa aktarıldı.`,
        type: 'info'
      });

      return true;
    } catch (error) {
      console.error('CSV export error:', error);
      addNotification({
        title: 'Hata',
        message: 'CSV dışa aktarımı sırasında hata oluştu.',
        type: 'error'
      });
      return false;
    } finally {
      setIsExporting(false);
      setTimeout(() => setExportProgress(0), 1000);
    }
  }, [user, prepareExportData, addNotification]);

  // Validate import data
  const validateImportData = useCallback((data: any): { isValid: boolean; errors: string[]; warnings: string[] } => {
    const errors: string[] = [];
    const warnings: string[] = [];

    if (!data || typeof data !== 'object') {
      errors.push('Geçersiz dosya formatı.');
      return { isValid: false, errors, warnings };
    }

    // Check for supported data types
    const supportedTypes = ['birds', 'chicks', 'breeding', 'eggs', 'incubations'];
    const hasValidData = supportedTypes.some(type => 
      data[type] && Array.isArray(data[type]) && data[type].length > 0
    );

    if (!hasValidData) {
      errors.push('İçe aktarılabilir veri bulunamadı.');
      return { isValid: false, errors, warnings };
    }

    // Validate each data type
    supportedTypes.forEach(type => {
      if (data[type] && Array.isArray(data[type])) {
        const items = data[type];
        const invalidItems = items.filter((item: any) => {
          if (!item || typeof item !== 'object') return true;
          
          // Basic validation based on type
          switch (type) {
            case 'birds':
            case 'chicks':
              return !item.name || typeof item.name !== 'string';
            case 'breeding':
              return !item.motherId && !item.fatherId;
            case 'eggs':
              return !item.layDate && !item.incubationId;
            case 'incubations':
              return !item.startDate;
            default:
              return false;
          }
        });

        if (invalidItems.length > 0) {
          warnings.push(`${type}: ${invalidItems.length} geçersiz kayıt atlanacak.`);
        }
      }
    });

    return { isValid: true, errors, warnings };
  }, []);

  // Import from file
  const importFromFile = useCallback(async (
    file: File, 
    onDataImported: (data: ExportData, stats: ImportStats) => Promise<void>
  ): Promise<boolean> => {
    if (!user) {
      addNotification({
        title: 'Hata',
        message: 'İçe aktarım için giriş yapmalısınız.',
        type: 'error'
      });
      return false;
    }

    setIsImporting(true);
    setImportProgress(0);

    try {
      // Validate file
      if (file.size > 10 * 1024 * 1024) { // 10MB limit
        throw new Error('Dosya boyutu 10MB\'dan büyük olamaz.');
      }

      const allowedExtensions = ['.json', '.csv'];
      const fileExtension = file.name.toLowerCase().substring(file.name.lastIndexOf('.'));
      
      if (!allowedExtensions.includes(fileExtension)) {
        throw new Error('Sadece JSON ve CSV dosyaları desteklenir.');
      }

      setImportProgress(20);

      // Read file
      const text = await file.text();
      setImportProgress(40);

      let data: any;
      
      if (fileExtension === '.json') {
        data = JSON.parse(text);
      } else if (fileExtension === '.csv') {
        // Simple CSV parsing - assumes first section is birds
        const lines = text.split('\n').filter(line => 
          line.trim() && !line.startsWith('#') && !line.startsWith('//'));
        
        if (lines.length < 2) {
          throw new Error('CSV dosyası geçersiz format.');
        }

        const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
        const rows = lines.slice(1).map(line => {
          const values = line.split(',').map(v => v.trim().replace(/^"|"$/g, ''));
          const obj: any = {};
          headers.forEach((header, index) => {
            obj[header] = values[index] || '';
          });
          return obj;
        });

        data = { birds: rows }; // Assume CSV is birds data
      }

      setImportProgress(60);

      // Validate data
      const validation = validateImportData(data);
      if (!validation.isValid) {
        throw new Error(validation.errors.join(', '));
      }

      setImportProgress(80);

      // Prepare import stats
      let totalProcessed = 0;
      let successfullyImported = 0;

      Object.keys(data).forEach(key => {
        if (Array.isArray(data[key])) {
          totalProcessed += data[key].length;
          // Filter out invalid items
          data[key] = data[key].filter((item: any) => {
            // Basic validation
            if (!item || typeof item !== 'object') return false;
            if ((key === 'birds' || key === 'chicks') && !item.name) return false;
            return true;
          });
          successfullyImported += data[key].length;
        }
      });

      const stats: ImportStats = {
        totalProcessed,
        successfullyImported,
        errors: totalProcessed - successfullyImported,
        warnings: validation.warnings
      };

      // Call the import handler
      await onDataImported(data, stats);

      setImportProgress(100);

      addNotification({
        title: 'İçe Aktarım Başarılı',
        message: `${successfullyImported}/${totalProcessed} kayıt başarıyla içe aktarıldı.`,
        type: 'info'
      });

      return true;
    } catch (error) {
      console.error('Import error:', error);
      addNotification({
        title: 'İçe Aktarım Hatası',
        message: error instanceof Error ? error.message : 'İçe aktarım sırasında hata oluştu.',
        type: 'error'
      });
      return false;
    } finally {
      setIsImporting(false);
      setTimeout(() => setImportProgress(0), 1000);
    }
  }, [user, validateImportData, addNotification]);

  // Quick export all data
  const exportAllData = useCallback(async (
    allData: ExportData, 
    format: 'json' | 'csv' = 'json'
  ): Promise<boolean> => {
    if (format === 'json') {
      return await exportToJSON(allData);
    } else {
      return await exportToCSV(allData);
    }
  }, [exportToJSON, exportToCSV]);

  return {
    // State
    isExporting,
    isImporting,
    exportProgress,
    importProgress,
    
    // Export functions
    exportToJSON,
    exportToCSV,
    exportAllData,
    prepareExportData,
    
    // Import functions
    importFromFile,
    validateImportData,
    
    // Utilities
    isProcessing: isExporting || isImporting
  };
}; 