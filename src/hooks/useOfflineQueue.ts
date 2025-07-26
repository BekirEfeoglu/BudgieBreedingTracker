
import { useState, useEffect } from 'react';

interface QueueItem {
  id: string;
  table?: string;
  operation: 'insert' | 'update' | 'delete' | 'bulk_delete_user_data';
  data: any;
  recordId?: string; // Separate field for record ID
  timestamp: string;
  retryCount: number;
  error?: string;
}

const STORAGE_KEY = 'offline_sync_queue';

export const useOfflineQueue = () => {
  const [queueSize, setQueueSize] = useState(0);

  // Load queue size on mount
  useEffect(() => {
    updateQueueSize();
  }, []);

  const getQueue = (): QueueItem[] => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      return stored ? JSON.parse(stored) : [];
    } catch (error) {
      console.error('Error reading sync queue:', error);
      return [];
    }
  };

  const setQueue = (queue: QueueItem[]) => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(queue));
      setQueueSize(queue.length);
    } catch (error) {
      console.error('Error saving sync queue:', error);
    }
  };

  const updateQueueSize = () => {
    setQueueSize(getQueue().length);
  };

  const addToQueue = (table: string, operation: 'insert' | 'update' | 'delete', data: any, recordId?: string) => {
    const queue = getQueue();
    
    // Clean up data - convert empty strings to null for UUID fields
    const cleanedData = { ...data };
    if (table === 'birds') {
      if (cleanedData.mother_id === '') cleanedData.mother_id = null;
      if (cleanedData.father_id === '') cleanedData.father_id = null;
      if (cleanedData.motherId === '') cleanedData.motherId = null;
      if (cleanedData.fatherId === '') cleanedData.fatherId = null;
    }
    
    const queueItem: QueueItem = {
      id: `${table}_${Date.now()}_${Math.random()}`,
      table,
      operation,
      data: cleanedData,
      timestamp: new Date().toISOString(),
      retryCount: 0
    };
    
    // Add record ID for update and delete operations
    if (recordId && (operation === 'update' || operation === 'delete')) {
      queueItem.recordId = recordId;
      // Remove id from data to avoid duplication
      const { id, ...dataWithoutId } = cleanedData;
      queueItem.data = dataWithoutId;
    }
    
    queue.push(queueItem);
    setQueue(queue);
    
    console.log(`📤 Added to sync queue: ${operation} on ${table}`, queueItem);
  };

  const clearQueue = () => {
    setQueue([]);
  };

  return {
    queueSize,
    getQueue,
    setQueue,
    addToQueue,
    clearQueue,
    updateQueueSize
  };
};

export type { QueueItem };
