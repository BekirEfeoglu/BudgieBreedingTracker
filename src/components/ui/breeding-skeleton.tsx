
import { Skeleton } from "@/components/ui/skeleton";
import { Card } from "@/components/ui/card";

export const BreedingCardSkeleton = () => (
  <Card className="p-4 animate-pulse">
    {/* Header skeleton */}
    <div className="flex items-start justify-between mb-4 gap-3">
      <div className="flex-1 min-w-0">
        <Skeleton className="h-6 w-48 mb-2" />
        <div className="space-y-2">
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-4 w-36" />
        </div>
      </div>
      <div className="flex gap-2">
        <Skeleton className="h-8 w-8 rounded" />
        <Skeleton className="h-8 w-8 rounded" />
      </div>
    </div>

    {/* Progress skeleton */}
    <div className="mb-4">
      <div className="flex items-center justify-between text-sm mb-2">
        <Skeleton className="h-4 w-24" />
        <Skeleton className="h-4 w-16" />
      </div>
      <Skeleton className="h-2 w-full rounded-full" />
    </div>

    {/* Eggs section skeleton */}
    <div className="space-y-3">
      <div className="flex items-center justify-between gap-2">
        <Skeleton className="h-4 w-20" />
        <Skeleton className="h-8 w-24 rounded" />
      </div>
      
      {/* Egg grid skeleton */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
        {Array.from({ length: 4 }).map((_, index) => (
          <div key={index} className="border rounded-lg p-3 min-h-[120px] flex flex-col">
            <div className="flex items-center justify-between mb-2">
              <Skeleton className="w-8 h-10 rounded-full" />
              <div className="flex gap-1">
                <Skeleton className="h-6 w-6 rounded" />
                <Skeleton className="h-6 w-6 rounded" />
              </div>
            </div>
            <div className="flex-1 flex flex-col justify-center items-center space-y-2">
              <Skeleton className="h-6 w-16 rounded-full" />
              <Skeleton className="h-4 w-12" />
            </div>
            <Skeleton className="h-3 w-20 mt-2" />
          </div>
        ))}
      </div>
    </div>

    {/* Footer skeleton */}
    <div className="mt-4 pt-3 border-t">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
        <Skeleton className="h-3 w-32" />
        <Skeleton className="h-3 w-36" />
      </div>
    </div>
  </Card>
);

export const EggCardSkeleton = () => (
  <div className="border rounded-lg p-3 min-h-[120px] flex flex-col animate-pulse">
    <div className="flex items-center justify-between mb-2">
      <Skeleton className="w-8 h-10 rounded-full" />
      <div className="flex gap-1">
        <Skeleton className="h-6 w-6 rounded" />
        <Skeleton className="h-6 w-6 rounded" />
      </div>
    </div>
    <div className="flex-1 flex flex-col justify-center items-center space-y-2">
      <Skeleton className="h-6 w-16 rounded-full" />
      <Skeleton className="h-4 w-12" />
    </div>
    <Skeleton className="h-3 w-20 mt-2" />
  </div>
);

export const BirdCardSkeleton = () => (
  <Card className="p-4 animate-pulse">
    <div className="flex items-start gap-4">
      <Skeleton className="w-16 h-16 rounded-full flex-shrink-0" />
      <div className="flex-1 min-w-0">
        <Skeleton className="h-5 w-32 mb-2" />
        <div className="space-y-1">
          <Skeleton className="h-4 w-24" />
          <Skeleton className="h-4 w-28" />
          <Skeleton className="h-4 w-20" />
        </div>
      </div>
      <div className="flex gap-2">
        <Skeleton className="h-8 w-8 rounded" />
        <Skeleton className="h-8 w-8 rounded" />
      </div>
    </div>
  </Card>
);

export const ChickCardSkeleton = () => (
  <Card className="p-4 animate-pulse">
    <div className="flex items-start gap-4">
      <Skeleton className="w-12 h-12 rounded-full flex-shrink-0" />
      <div className="flex-1 min-w-0">
        <Skeleton className="h-5 w-28 mb-2" />
        <div className="space-y-1">
          <Skeleton className="h-4 w-20" />
          <Skeleton className="h-4 w-24" />
        </div>
      </div>
      <div className="flex gap-2">
        <Skeleton className="h-8 w-8 rounded" />
        <Skeleton className="h-8 w-8 rounded" />
      </div>
    </div>
  </Card>
);
