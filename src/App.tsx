import React, { Suspense, useCallback, useState } from 'react';
import { HashRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from '@/contexts/ThemeContext';
import { LanguageProvider } from '@/contexts/LanguageContext';
import { Toaster } from '@/components/ui/toaster';
import GlobalErrorBoundary from '@/components/errors/GlobalErrorBoundary';
import LoadingSpinner from '@/components/ui/loading-spinner';
import './App.css';
import { AuthProvider } from '@/hooks/useAuth';
import ProtectedRoute from '@/components/ProtectedRoute';
import { useBirdsData } from '@/hooks/bird/useBirdsData';
import { useChicksData } from '@/hooks/chick/useChicksData';
import { useClutchesData } from '@/hooks/useClutchesData';
import { useEggsData } from '@/hooks/useEggsData';
import { Bird } from '@/types';
import { NotificationProvider } from '@/contexts/notifications';
import { MainLayout } from '@/layouts/MainLayout';
import BirdForm from '@/components/BirdForm';
import { useSupabaseOperations } from '@/hooks/useSupabaseOperations';
import { useToast } from '@/hooks/use-toast';
import { AuthDebug } from '@/components/auth/AuthDebug';
import { SignupTest } from '@/components/auth/SignupTest';
import { useBirdUpdate } from '@/hooks/bird/useBirdUpdate';
import { useBirdDelete } from '@/hooks/bird/useBirdDelete';
import { useSessionSecurity } from '@/hooks/useSessionSecurity';

// Lazy load components for better performance
const Index = React.lazy(() => import('@/pages/Index'));
const LoginPage = React.lazy(() => import('@/pages/LoginPage'));
const NotFound = React.lazy(() => import('@/pages/NotFound'));
const UserGuidePage = React.lazy(() => import('@/pages/UserGuidePage'));

const Dashboard = React.lazy(() => import('@/components/Dashboard'));
const QuickTestPage = React.lazy(() => import('@/pages/QuickTestPage'));
const EmergencyTestPage = React.lazy(() => import('@/pages/EmergencyTestPage'));
const PremiumPage = React.lazy(() => import('@/components/premium/PremiumPage'));
const PremiumSystemTest = React.lazy(() => import('@/components/premium/PremiumSystemTest'));

// Optimize QueryClient configuration for better performance
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 5 * 60 * 1000, // 5 minutes
      gcTime: 10 * 60 * 1000, // 10 minutes
    },
    mutations: {
      retry: 1,
    },
  },
});

const AppContainer = () => {
  const { birds, setBirds, loading: birdsLoading } = useBirdsData();
  const { chicks, setChicks, loading: chicksLoading } = useChicksData();
  const { eggs, loading: eggsLoading } = useEggsData();
  const isLoading = birdsLoading || chicksLoading || eggsLoading;

  // Güvenlik hook'ları
  useSessionSecurity();

  // Kuş form state'leri
  const [isBirdFormOpen, setIsBirdFormOpen] = useState(false);
  const [editingBird, setEditingBird] = useState<Bird | null>(null);
  
  // Tab değişimi için ref
  const dashboardRef = React.useRef<{ handleTabChange: (tab: string) => void } | null>(null);

  // Kuş işlemleri
  const handleAddBird = useCallback(() => {
    setEditingBird(null);
    setIsBirdFormOpen(true);
  }, []);

  const handleEditBird = useCallback((bird: Bird) => {
    setEditingBird(bird);
    setIsBirdFormOpen(true);
  }, []);

  const { insertRecord } = useSupabaseOperations();
  const { toast } = useToast();
  const { editBird } = useBirdUpdate(birds, setBirds);
  const { deleteBird } = useBirdDelete(birds, setBirds);

  const handleDeleteBird = useCallback(async (birdId: string) => {
    try {
      await deleteBird(birdId);
    } catch (error) {
      console.error('Kuş silme hatası:', error);
      toast({ 
        title: 'Hata', 
        description: 'Kuş silinirken bir hata oluştu.', 
        variant: 'destructive' 
      });
    }
  }, [deleteBird, toast]);

  const handleSaveBird = useCallback(async (birdData: Partial<Bird> & { birthDate?: Date }) => {
    try {
      if (editingBird) {
        // Kuş düzenleme - birthDate'i string'e çevir
        const updatedBird: Bird = { 
          ...editingBird, 
          ...birdData,
          birthDate: birdData.birthDate ? birdData.birthDate.toISOString().split('T')[0] : (editingBird.birthDate || '')
        };
        
        console.log('🔄 Kuş güncelleniyor:', updatedBird);
        await editBird(updatedBird);
        
        toast({
          title: 'Başarılı',
          description: `"${updatedBird.name}" adlı kuş başarıyla güncellendi.`,
        });
      } else {
        // Yeni kuş ekleme - Optimistic update ile hemen local state'e ekle
        const newBirdId = crypto.randomUUID();
        const newBird: Bird = {
          id: newBirdId,
          name: birdData.name || '',
          gender: birdData.gender || 'unknown',
          color: birdData.color || '',
          birthDate: birdData.birthDate ? birdData.birthDate.toISOString().split('T')[0] : '',
          ringNumber: birdData.ringNumber || '',
          healthNotes: birdData.healthNotes || '',
          photo: birdData.photo || '',
          motherId: birdData.motherId || '',
          fatherId: birdData.fatherId || '',
        };

        // Optimistic update - hemen UI'da göster (duplicate kontrolü ile)
        setBirds(prev => {
          // Check if bird already exists to prevent duplicates
          const exists = prev.some(bird => bird.id === newBird.id);
          if (exists) {
            console.log('🔄 Bird already exists in optimistic update, skipping:', newBird.name);
            return prev;
          }
          return [newBird, ...prev];
        });

        // Supabase'e kaydet
        const result = await insertRecord('birds', newBird);
        
        if (result.success) {
          toast({
            title: 'Başarılı',
            description: `"${newBird.name}" adlı kuş başarıyla eklendi.`,
          });
        } else {
          // Hata durumunda geri al
          setBirds(prev => prev.filter(bird => bird.id !== newBirdId));
          throw new Error(result.error || 'Kuş eklenirken bir hata oluştu.');
        }
      }

      setIsBirdFormOpen(false);
      setEditingBird(null);
    } catch (error) {
      console.error('Kuş kaydetme hatası:', error);
      toast({
        title: 'Hata',
        description: 'Kuş kaydedilirken bir hata oluştu.',
        variant: 'destructive',
      });
    }
  }, [editingBird, setBirds, insertRecord, editBird, toast]);

  const handleCloseBirdForm = useCallback(() => {
    setIsBirdFormOpen(false);
    setEditingBird(null);
  }, []);

  const handleTabChange = useCallback((tab: string) => {
    if (dashboardRef.current) {
      dashboardRef.current.handleTabChange(tab);
    }
  }, []);

  return (
    <MainLayout onTabChange={handleTabChange}>
      <Suspense fallback={<LoadingSpinner />}>
        <Dashboard
          ref={dashboardRef}
          birds={birds}
          eggs={eggs}
          chicks={chicks}
          isLoading={isLoading}
          onBirdAdd={handleAddBird}
          onBirdEdit={handleEditBird}
          onBirdDelete={handleDeleteBird}
          onBirdSave={handleSaveBird as any}
          onBirdFormClose={handleCloseBirdForm}
          isBirdFormOpen={isBirdFormOpen}
          editingBird={editingBird}
        />
      </Suspense>

      {/* Bird Form Modal */}
      {isBirdFormOpen && (
        <BirdForm
          isOpen={isBirdFormOpen}
          onClose={handleCloseBirdForm}
          onSave={handleSaveBird}
          editingBird={editingBird}
          existingBirds={birds}
        />
      )}
    </MainLayout>
  );
};

// Simple App without complex authentication for mobile
function App() {
  return (
    <GlobalErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <LanguageProvider>
            <AuthProvider>
              <NotificationProvider>
                <Router>
                  <div className="App">
                    <Suspense fallback={<LoadingSpinner />}>
                      <Routes>
                        <Route path="/login" element={<LoginPage />} />
                        <Route path="/*" element={
                          <ProtectedRoute>
                            <Routes>
                              <Route path="/" element={<AppContainer />} />

                              <Route path="/debug" element={<AuthDebug />} />
                              <Route path="/signup-test" element={<SignupTest />} />
                              <Route path="/quick-test" element={<QuickTestPage />} />
                              <Route path="/emergency-test" element={<EmergencyTestPage />} />
                              <Route path="/user-guide" element={<UserGuidePage />} />
                              <Route path="/premium" element={<PremiumPage />} />
                              <Route path="/premium-test" element={<PremiumSystemTest />} />
                              <Route path="*" element={<NotFound />} />
                            </Routes>
                          </ProtectedRoute>
                        } />
                      </Routes>
                    </Suspense>
                    <Toaster />
                  </div>
                </Router>
              </NotificationProvider>
            </AuthProvider>
          </LanguageProvider>
        </ThemeProvider>
      </QueryClientProvider>
    </GlobalErrorBoundary>
  );
}

export default App;
