import React from 'react';
import { useAuth } from '@/hooks/useAuth';

export const AuthDebug: React.FC = () => {
  const { user, loading } = useAuth();

  if (loading) {
    return <div>Yükleniyor...</div>;
  }

  return (
    <div className="p-4 border rounded-lg bg-gray-50">
      <h3 className="text-lg font-semibold mb-2">Auth Debug</h3>
      <pre className="text-sm">
        {JSON.stringify({ user, loading }, null, 2)}
      </pre>
    </div>
  );
}; 