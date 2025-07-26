import React, { useState, useEffect } from 'react';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useRingNumberValidation } from '@/hooks/useRingNumberValidation';
import { CheckCircle, XCircle, Loader2 } from 'lucide-react';
import { useDebounce } from '@/hooks/useDebounce';

interface RingNumberFieldProps {
  value: string;
  onChange: (value: string) => void;
  excludeId?: string;
  label?: string;
  placeholder?: string;
  required?: boolean;
  error?: string;
}

export const RingNumberField: React.FC<RingNumberFieldProps> = ({
  value,
  onChange,
  excludeId,
  label = 'Halka Numarası',
  placeholder = 'Örn: TR2024001',
  required = false,
  error
}) => {
  const [validationState, setValidationState] = useState<{
    status: 'idle' | 'checking' | 'valid' | 'invalid';
    message?: string;
  }>({ status: 'idle' });

  const { validateRingNumberUniqueness } = useRingNumberValidation();
  const debouncedValue = useDebounce(value, 500);

  useEffect(() => {
    const checkRingNumber = async () => {
      if (!debouncedValue || debouncedValue.trim() === '') {
        setValidationState({ status: 'idle' });
        return;
      }

      if (debouncedValue.length < 2) {
        setValidationState({ 
          status: 'invalid', 
          message: 'Halka numarası en az 2 karakter olmalıdır' 
        });
        return;
      }

      setValidationState({ status: 'checking' });

      const result = await validateRingNumberUniqueness(debouncedValue, excludeId);
      
      setValidationState({
        status: result.isValid ? 'valid' : 'invalid',
        message: result.message
      });
    };

    checkRingNumber();
  }, [debouncedValue, validateRingNumberUniqueness, excludeId]);

  const getStatusIcon = () => {
    switch (validationState.status) {
      case 'checking':
        return <Loader2 className="w-4 h-4 animate-spin text-muted-foreground" />;
      case 'valid':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'invalid':
        return <XCircle className="w-4 h-4 text-destructive" />;
      default:
        return null;
    }
  };

  const getBorderColor = () => {
    if (error) return 'border-destructive';
    
    switch (validationState.status) {
      case 'valid':
        return 'border-green-500';
      case 'invalid':
        return 'border-destructive';
      default:
        return '';
    }
  };

  return (
    <div className="space-y-2">
      <Label htmlFor="ring-number" className="text-sm font-medium">
        {label}
        {required && <span className="text-destructive ml-1">*</span>}
      </Label>
      <div className="relative">
        <Input
          id="ring-number"
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className={`pr-10 ${getBorderColor()}`}
          maxLength={20}
        />
        <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
          {getStatusIcon()}
        </div>
      </div>
      {(error || validationState.message) && (
        <p className="text-sm text-destructive">
          {error || validationState.message}
        </p>
      )}
      {validationState.status === 'valid' && value && (
        <p className="text-sm text-green-600">
          ✓ Halka numarası kullanılabilir
        </p>
      )}
      <p className="text-xs text-muted-foreground">
        Halka numarası sadece harf, rakam ve tire (-) içerebilir. Aynı kullanıcı için benzersiz olmalıdır.
      </p>
    </div>
  );
};