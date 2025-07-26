import { useState, useCallback, useRef, useEffect } from 'react';
import { useToast } from '@/hooks/use-toast';

interface RetryQueueItem {
  id: string;
  operation: () => Promise<any>;
  data: any;
  attempts: number;
  maxAttempts: number;
  backoffMs: number;
  lastAttempt: Date;
  context: string;
}

interface RetryQueueOptions {
  maxAttempts: number;
  initialBackoffMs: number;
  maxBackoffMs: number;
  backoffMultiplier: number;
}

export const useRetryQueue = (options: RetryQueueOptions = {
  maxAttempts: 3,
  initialBackoffMs: 1000,
  maxBackoffMs: 30000,
  backoffMultiplier: 2
}) => {
  const [queue, setQueue] = useState<RetryQueueItem[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout>();
  const { toast } = useToast();

  const addToQueue = useCallback((
    operation: () => Promise<any>,
    data: any,
    context: string = 'Operation'
  ) => {
    const item: RetryQueueItem = {
      id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
      operation,
      data,
      attempts: 0,
      maxAttempts: options.maxAttempts,
      backoffMs: options.initialBackoffMs,
      lastAttempt: new Date(),
      context
    };

    setQueue(prev => [...prev, item]);
    return item.id;
  }, [options.maxAttempts, options.initialBackoffMs]);

  const removeFromQueue = useCallback((id: string) => {
    setQueue(prev => prev.filter(item => item.id !== id));
  }, []);

  const calculateBackoff = useCallback((attempts: number) => {
    const backoff = options.initialBackoffMs * Math.pow(options.backoffMultiplier, attempts);
    return Math.min(backoff, options.maxBackoffMs);
  }, [options]);

  const processQueue = useCallback(async () => {
    if (isProcessing || queue.length === 0) return;

    setIsProcessing(true);

    try {
      const now = new Date();
      const readyItems = queue.filter(item => {
        const timeSinceLastAttempt = now.getTime() - item.lastAttempt.getTime();
        return timeSinceLastAttempt >= item.backoffMs;
      });

      if (readyItems.length === 0) {
        // Schedule next processing
        const nextRetry = Math.min(...queue.map(item => 
          item.lastAttempt.getTime() + item.backoffMs - now.getTime()
        ));
        
        if (nextRetry > 0) {
          timeoutRef.current = setTimeout(processQueue, nextRetry);
        }
        return;
      }

      // Process one item at a time to avoid overwhelming
      const item = readyItems[0];
      
      try {
        await item.operation();
        removeFromQueue(item.id);
        
        toast({
          title: 'Senkronizasyon Başarılı',
          description: `${item.context} başarıyla tamamlandı.`,
        });
      } catch (error) {
        const updatedItem = {
          ...item,
          attempts: item.attempts + 1,
          lastAttempt: now,
          backoffMs: calculateBackoff(item.attempts + 1)
        };

        if (updatedItem.attempts >= updatedItem.maxAttempts) {
          removeFromQueue(item.id);
          
          toast({
            title: 'Senkronizasyon Başarısız',
            description: `${item.context} ${updatedItem.maxAttempts} denemeden sonra başarısız oldu.`,
            variant: 'destructive'
          });
        } else {
          setQueue(prev => prev.map(q => q.id === item.id ? updatedItem : q));
        }
      }

      // Schedule next processing
      timeoutRef.current = setTimeout(processQueue, 100);
    } finally {
      setIsProcessing(false);
    }
  }, [isProcessing, queue, removeFromQueue, calculateBackoff, toast]);

  // Auto-process queue when items are added
  useEffect(() => {
    if (queue.length > 0 && !isProcessing) {
      const timer = setTimeout(processQueue, 100);
      return () => clearTimeout(timer);
    }
  }, [queue.length, isProcessing, processQueue]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, []);

  const clearQueue = useCallback(() => {
    setQueue([]);
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
  }, []);

  const retryAll = useCallback(() => {
    setQueue(prev => prev.map(item => ({
      ...item,
      attempts: 0,
      backoffMs: options.initialBackoffMs,
      lastAttempt: new Date(0) // Force immediate retry
    })));
  }, [options.initialBackoffMs]);

  return {
    queue,
    queueSize: queue.length,
    isProcessing,
    addToQueue,
    removeFromQueue,
    clearQueue,
    retryAll,
    processQueue
  };
};