import { useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';

export const useRingNumberValidation = () => {
  const { user } = useAuth();

  const validateRingNumberUniqueness = useCallback(async (
    ringNumber: string, 
    excludeId?: string
  ): Promise<{ isValid: boolean; message?: string }> => {
    if (!user || !ringNumber || ringNumber.trim() === '') {
      return { isValid: true };
    }

    try {
      let query = supabase
        .from('birds')
        .select('id, name, ring_number')
        .eq('user_id', user.id)
        .eq('ring_number', ringNumber.trim());

      if (excludeId) {
        query = query.neq('id', excludeId);
      }

      const { data, error } = await query;

      if (error) {
        console.error('Ring number validation error:', error);
        return { 
          isValid: false, 
          message: 'Halka numarası kontrolü sırasında hata oluştu' 
        };
      }

      if (data && data.length > 0) {
        const existingBird = data[0];
        return { 
          isValid: false, 
          message: `Bu halka numarası zaten "${existingBird.name}" isimli kuşa ait` 
        };
      }

      return { isValid: true };
    } catch (error) {
      console.error('Ring number validation error:', error);
      return { 
        isValid: false, 
        message: 'Halka numarası kontrolü sırasında beklenmedik hata oluştu' 
      };
    }
  }, [user]);

  const checkRingNumberAvailability = useCallback(async (
    ringNumber: string,
    excludeId?: string
  ): Promise<boolean> => {
    const result = await validateRingNumberUniqueness(ringNumber, excludeId);
    return result.isValid;
  }, [validateRingNumberUniqueness]);

  return {
    validateRingNumberUniqueness,
    checkRingNumberAvailability
  };
};