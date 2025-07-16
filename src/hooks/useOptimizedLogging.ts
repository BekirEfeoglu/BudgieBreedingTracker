import { useCallback } from 'react';

interface LoggingOptions {
  enabled?: boolean;
  level?: 'log' | 'warn' | 'error' | 'debug';
  context?: string;
}

export const useOptimizedLogging = () => {
  const isDevelopment = process.env.NODE_ENV === 'development';

  const log = useCallback((
    message: string, 
    data?: any, 
    options: LoggingOptions = {}
  ) => {
    const { enabled = isDevelopment, level = 'log', context } = options;
    
    if (!enabled) return;

    const prefix = context ? `[${context}]` : '';
    const logMessage = `${prefix} ${message}`;
    
    if (data !== undefined) {
      console[level](logMessage, data);
    } else {
      console[level](logMessage);
    }
  }, [isDevelopment]);

  const debug = useCallback((message: string, data?: any, context?: string) => {
    log(message, data, { level: 'debug', context });
  }, [log]);

  const warn = useCallback((message: string, data?: any, context?: string) => {
    log(message, data, { level: 'warn', context });
  }, [log]);

  const error = useCallback((message: string, data?: any, context?: string) => {
    log(message, data, { level: 'error', context, enabled: true }); // Always log errors
  }, [log]);

  return { log, debug, warn, error };
};