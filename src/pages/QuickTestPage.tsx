import React from 'react';
import { AuthDebug } from '@/components/auth/AuthDebug';
import { SignupTest } from '@/components/auth/SignupTest';

const QuickTestPage: React.FC = () => {
  return (
    <div className="container mx-auto p-4 space-y-4">
      <h1 className="text-2xl font-bold">Hızlı Test Sayfası</h1>
      <AuthDebug />
      <SignupTest />
    </div>
  );
};

export default QuickTestPage; 