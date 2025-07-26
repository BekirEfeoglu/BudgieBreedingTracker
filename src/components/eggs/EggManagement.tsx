import React from 'react';
import EggManagementHeader from './EggManagementHeader';
import EggManagementContent from './EggManagementContent';
import ErrorBoundary from './ErrorBoundary';
import EggManagementError from './EggManagementError';

interface EggManagementProps {
  clutchId: string;
  clutchName: string;
  onBack: () => void;
  autoOpenForm?: boolean;
  onNavigateToBreeding?: () => void;
}

const EggManagement: React.FC<EggManagementProps> = ({
  clutchId,
  clutchName,
  onBack,
  autoOpenForm = false,
  onNavigateToBreeding
}) => {
  const handleRefresh = () => {
    // Force a page refresh or trigger a refetch
    window.location.reload();
  };

  const handleError = (error: Error) => {
    console.error('🚨 EggManagement Error:', error);
    return (
      <EggManagementError 
        error={error.message} 
        onRefresh={handleRefresh}
      />
    );
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto p-4 space-y-6">
        {/* Header */}
        <EggManagementHeader 
          clutchName={clutchName}
          onBack={onBack}
          onRefresh={handleRefresh}
        />

        {/* Content with Error Boundary */}
        <ErrorBoundary fallbackRender={({ error }) => handleError(error)}>
          <EggManagementContent
            clutchId={clutchId}
            autoOpenForm={autoOpenForm}
            onNavigateToBreeding={onNavigateToBreeding || (() => {})}
          />
        </ErrorBoundary>
      </div>
    </div>
  );
};

export default EggManagement;
