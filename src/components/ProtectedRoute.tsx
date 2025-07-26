import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSecureAuth } from '@/hooks/useSecureAuth';
import { useOptimizedLogging } from '@/hooks/useOptimizedLogging';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

const ProtectedRoute = ({ children }: ProtectedRouteProps) => {
  const { user, loading } = useSecureAuth();
  const navigate = useNavigate();
  const { debug } = useOptimizedLogging();

  useEffect(() => {
    // Log authentication state for debugging in development
    debug('ProtectedRoute check', { 
      userId: user?.id, 
      hasUser: !!user, 
      loading 
    }, 'Auth');
  }, [user, loading, debug]);

  useEffect(() => {
    // Redirect unauthenticated users to login
    if (!loading && !user) {
      debug('Redirecting unauthenticated user to login', undefined, 'Auth');
      navigate('/login', { replace: true });
    }
  }, [user, loading, navigate, debug]);

  // Show enhanced loading state while checking authentication
  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-budgie-cream via-budgie-warm to-budgie-cream flex items-center justify-center overflow-hidden">
        {/* Background decorative elements */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-20 left-10 w-20 h-20 budgie-gradient rounded-full opacity-20 animate-bounce-gentle" 
               style={{ animationDelay: '0s', animationDuration: '3s' }}></div>
          <div className="absolute top-40 right-20 w-16 h-16 bg-accent/20 rounded-full animate-bounce-gentle" 
               style={{ animationDelay: '1s', animationDuration: '4s' }}></div>
          <div className="absolute bottom-32 left-1/4 w-12 h-12 bg-primary/20 rounded-full animate-bounce-gentle" 
               style={{ animationDelay: '2s', animationDuration: '5s' }}></div>
        </div>

        {/* Loading content */}
        <div className="text-center z-10 p-6">
          <div className="animate-spin rounded-full h-16 w-16 border-4 border-primary border-t-transparent mx-auto mb-6"></div>
          <h2 className="text-2xl font-semibold text-primary mb-2">BudgieBreedingTracker</h2>
          <p className="text-muted-foreground text-lg">Giriş kontrol ediliyor...</p>
        </div>

        {/* Background pattern */}
        <div className="absolute inset-0 opacity-5">
          <div className="w-full h-full" style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23000' fill-opacity='0.1'%3E%3Ccircle cx='30' cy='30' r='2'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
          }} />
        </div>
      </div>
    );
  }

  // Show content if authenticated
  if (user) {
    return <>{children}</>;
  }

  // Return null while redirecting
  return null;
};

export default ProtectedRoute;
