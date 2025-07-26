
import { useCallback } from 'react';
import { useToast } from '@/hooks/use-toast';

interface ErrorReportingOptions {
  showToast?: boolean;
  toastTitle?: string;
  toastDescription?: string;
}

export const useErrorReporting = () => {
  const { toast } = useToast();

  const reportError = useCallback((
    error: Error,
    context?: string,
    options: ErrorReportingOptions = {}
  ) => {
    const {
      showToast = true,
      toastTitle = 'Hata',
      toastDescription = 'Bir hata oluştu. Lütfen tekrar deneyin.'
    } = options;

    // Log error for debugging
    console.error(`🔴 Error reported${context ? ` in ${context}` : ''}:`, error);
    
    // Show toast notification if enabled
    if (showToast) {
      toast({
        title: toastTitle,
        description: toastDescription,
        variant: 'destructive'
      });
    }

    // Here you could add external error reporting service
    // Example: Sentry.captureException(error, { tags: { context } });
    
    return {
      logged: true,
      timestamp: new Date().toISOString(),
      context
    };
  }, [toast]);

  const reportWarning = useCallback((
    message: string,
    context?: string,
    showToast: boolean = false
  ) => {
    console.warn(`⚠️ Warning${context ? ` in ${context}` : ''}: ${message}`);
    
    if (showToast) {
      toast({
        title: 'Uyarı',
        description: message,
        variant: 'default'
      });
    }
  }, [toast]);

  return {
    reportError,
    reportWarning
  };
};
