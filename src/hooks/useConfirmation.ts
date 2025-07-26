
import { useState } from 'react';

interface ConfirmationConfig {
  title: string;
  description: string;
  confirmText?: string;
  cancelText?: string;
  variant?: 'default' | 'destructive';
}

export const useConfirmation = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [config, setConfig] = useState<ConfirmationConfig>({
    title: '',
    description: ''
  });
  const [onConfirm, setOnConfirm] = useState<(() => void) | null>(null);

  const confirm = (config: ConfirmationConfig, callback: () => void) => {
    setConfig(config);
    setOnConfirm(() => callback);
    setIsOpen(true);
  };

  const handleConfirm = () => {
    if (onConfirm) {
      onConfirm();
    }
    setIsOpen(false);
    setOnConfirm(null);
  };

  const handleCancel = () => {
    setIsOpen(false);
    setOnConfirm(null);
  };

  return {
    isOpen,
    config,
    confirm,
    handleConfirm,
    handleCancel
  };
};
