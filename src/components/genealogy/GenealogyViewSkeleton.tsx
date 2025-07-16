import React, { memo } from 'react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { useLanguage } from '@/contexts/LanguageContext';

const GenealogyViewSkeleton = memo(() => {
  const { t } = useLanguage();

  return (
    <div className="space-y-6 pb-20 md:pb-4 px-2 md:px-0" role="status" aria-live="polite" aria-label={t('common.loading')}>
      {/* Header skeleton */}
      <div className="text-center lg:text-left">
        <Skeleton className="h-8 w-48 mx-auto lg:mx-0 mb-2" aria-hidden="true" />
        <Skeleton className="h-4 w-64 mx-auto lg:mx-0" aria-hidden="true" />
      </div>

      {/* Search skeleton */}
      <Card className="enhanced-card">
        <CardHeader className="pb-3">
          <Skeleton className="h-5 w-32" aria-hidden="true" />
        </CardHeader>
        <CardContent>
          <Skeleton className="h-10 w-full mb-3" aria-hidden="true" />
          <Skeleton className="h-4 w-40" aria-hidden="true" />
        </CardContent>
      </Card>

      {/* Family tree skeleton */}
      <Card className="enhanced-card">
        <CardHeader className="pb-3">
          <Skeleton className="h-5 w-48" aria-hidden="true" />
        </CardHeader>
        <CardContent>
          {/* Control buttons skeleton */}
          <div className="flex justify-between items-center mb-4">
            <div className="flex gap-2">
              <Skeleton className="h-9 w-9 rounded" aria-hidden="true" />
              <Skeleton className="h-9 w-9 rounded" aria-hidden="true" />
              <Skeleton className="h-9 w-9 rounded" aria-hidden="true" />
            </div>
            <Skeleton className="h-4 w-20" aria-hidden="true" />
          </div>

          {/* Tree canvas skeleton */}
          <div className="relative w-full h-80 md:h-[500px] border-2 border-border rounded-lg overflow-hidden bg-muted/20">
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="space-y-4 text-center">
                <Skeleton className="w-20 h-20 rounded-full mx-auto" aria-hidden="true" />
                <div className="space-y-2">
                  <Skeleton className="h-4 w-32 mx-auto" aria-hidden="true" />
                  <Skeleton className="h-3 w-48 mx-auto" aria-hidden="true" />
                </div>
              </div>
            </div>
          </div>

          {/* Statistics skeleton */}
          <div className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4">
            {Array.from({ length: 4 }).map((_, index) => (
              <div key={index} className="text-center p-3 bg-muted/50 rounded-lg">
                <Skeleton className="w-8 h-8 mx-auto mb-1" aria-hidden="true" />
                <Skeleton className="h-4 w-6 mx-auto mb-1" aria-hidden="true" />
                <Skeleton className="h-3 w-12 mx-auto" aria-hidden="true" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
});

GenealogyViewSkeleton.displayName = 'GenealogyViewSkeleton';

export default GenealogyViewSkeleton;
