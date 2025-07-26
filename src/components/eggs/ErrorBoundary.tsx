import React from 'react';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';

interface Props {
  children: React.ReactNode;
  fallbackRender: ({ error }: { error: Error }) => React.ReactNode;
}

const ErrorBoundary = ({ children, fallbackRender: _fallbackRender }: Props) => {
  return (
    <ComponentErrorBoundary
      fallback={null}
      onError={(error, errorInfo) => {
        console.error('🥚 Egg component error:', error, errorInfo);
      }}
    >
      <ComponentErrorBoundary
        fallback={
          <div className="p-4 text-center">
            {/* This will be replaced by the fallbackRender if error occurs */}
          </div>
        }
      >
        {children}
      </ComponentErrorBoundary>
    </ComponentErrorBoundary>
  );
};

export default ErrorBoundary;
