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
import { useBirdUpdate } from '@/hooks/bird/useBirdUpdate';
import { useBirdDelete } from '@/hooks/bird/useBirdDelete';

// Lazy load components for better performance
const Index = React.lazy(() => import('@/pages/Index'));
const LoginPage = React.lazy(() => import('@/pages/LoginPage'));
const NotFound = React.lazy(() => import('@/pages/NotFound'));
const ProfilePage = React.lazy(() => import('@/components/profile/ProfilePage'));
const Dashboard = React.lazy(() => import('@/components/Dashboard'));

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
  const { clutches, loading: clutchesLoading } = useClutchesData();
  const { eggs, loading: eggsLoading } = useEggsData();
  const isLoading = birdsLoading || chicksLoading || clutchesLoading || eggsLoading;

  // Kuş form state'leri
  const [isBirdFormOpen, setIsBirdFormOpen] = useState(false);
  const [editingBird, setEditingBird] = useState<Bird | null>(null);

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

  const handleSaveBird = useCallback(async (birdData: Partial<Bird>) => {
    try {
      if (editingBird) {
        // Kuş düzenleme
        const updatedBird = { ...editingBird, ...birdData };
        await editBird(updatedBird); // Supabase'e de güncelleme gönder
      } else {
        // Yeni kuş ekleme
        const newBird = {
          id: Date.now().toString(),
          ...birdData
        } as Bird;
        // Supabase'e kaydet
        const result = await insertRecord('birds', {
          name: newBird.name,
          gender: newBird.gender,
          color: newBird.color ? newBird.color : null,
          birth_date: newBird.birthDate ? (typeof newBird.birthDate === 'string' ? newBird.birthDate : new Date(newBird.birthDate).toISOString().split('T')[0]) : null,
          ring_number: newBird.ringNumber ? newBird.ringNumber : null,
          photo_url: newBird.photo ? newBird.photo : null,
          health_notes: newBird.healthNotes ? newBird.healthNotes : null,
          mother_id: newBird.motherId ? newBird.motherId : null,
          father_id: newBird.fatherId ? newBird.fatherId : null
        });
        if (result.success) {
          setBirds(prev => [...prev, newBird]);
          toast({ title: 'Başarılı', description: 'Kuş başarıyla eklendi.' });
        } else {
          toast({ title: 'Hata', description: 'Kuş eklenirken bir hata oluştu.', variant: 'destructive' });
        }
      }
      setIsBirdFormOpen(false);
      setEditingBird(null);
    } catch (error) {
      console.error('Kuş kaydetme hatası:', error);
      toast({ 
        title: 'Hata', 
        description: 'Kuş kaydedilirken bir hata oluştu.', 
        variant: 'destructive' 
      });
    }
  }, [editingBird, setBirds, insertRecord, toast, editBird]);

  const handleCloseBirdForm = useCallback(() => {
    setIsBirdFormOpen(false);
    setEditingBird(null);
  }, []);

  return (
    <>
      <Dashboard
        birds={birds}
        clutches={clutches}
        eggs={eggs}
        chicks={chicks}
        isLoading={isLoading}
        onBirdAdd={handleAddBird}
        onBirdEdit={handleEditBird}
        onBirdDelete={handleDeleteBird}
        onBirdSave={handleSaveBird}
        onBirdFormClose={handleCloseBirdForm}
        isBirdFormOpen={isBirdFormOpen}
        editingBird={editingBird}
      />
      
      <BirdForm
        isOpen={isBirdFormOpen}
        onClose={handleCloseBirdForm}
        onSave={handleSaveBird}
        existingBirds={birds}
        editingBird={editingBird}
      />
    </>
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
                              <Route path="/" element={<MainLayout><AppContainer /></MainLayout>} />
                              <Route path="/profile" element={<MainLayout><ProfilePage onBack={() => window.location.hash = '#/'} /></MainLayout>} />
                              <Route path="/debug" element={<AuthDebug />} />
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
