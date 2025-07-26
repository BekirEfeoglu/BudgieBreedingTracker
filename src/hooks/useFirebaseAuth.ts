import { useState, useEffect, useRef } from 'react';
import { 
  User as FirebaseUser,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  sendPasswordResetEmail,
  updateProfile
} from 'firebase/auth';
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { auth, db } from '@/integrations/firebase/config';
import { Profile, COLLECTIONS } from '@/integrations/firebase/types';

interface AuthContextType {
  user: FirebaseUser | null;
  profile: Profile | null;
  loading: boolean;
  signUp: (email: string, password: string, firstName?: string, lastName?: string) => Promise<{ error: string | null }>;
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error: string | null }>;
  updateProfile: (updates: Partial<Profile>) => Promise<{ error: string | null }>;
}

export const useFirebaseAuth = (): AuthContextType => {
  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const initializationRef = useRef(false);

  // Profile'ı Firestore'dan yükle
  const fetchProfile = async (userId: string): Promise<void> => {
    try {
      const profileDoc = await getDoc(doc(db, COLLECTIONS.PROFILES, userId));
      
      if (profileDoc.exists()) {
        const profileData = profileDoc.data() as Profile;
        setProfile(profileData);
        console.log('✅ Profile yüklendi');
      } else {
        // Profile yoksa oluştur
        const newProfile: Profile = {
          id: userId,
          first_name: null,
          last_name: null,
          avatar_url: null,
          updated_at: new Date().toISOString()
        };
        
        await setDoc(doc(db, COLLECTIONS.PROFILES, userId), newProfile);
        setProfile(newProfile);
        console.log('✅ Yeni profile oluşturuldu');
      }
    } catch (error) {
      console.error('❌ Profile yükleme hatası:', error);
    }
  };

  // Auth state listener
  useEffect(() => {
    if (initializationRef.current) return;
    
    initializationRef.current = true;
    console.log('🔄 Firebase Auth başlatılıyor...');

    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      console.log('🔐 Auth state değişti:', firebaseUser?.email);
      
      setUser(firebaseUser);
      
      if (firebaseUser) {
        await fetchProfile(firebaseUser.uid);
      } else {
        setProfile(null);
      }
      
      setLoading(false);
    });

    return () => {
      unsubscribe();
      initializationRef.current = false;
    };
  }, []);

  // Kayıt olma
  const signUp = async (email: string, password: string, firstName?: string, lastName?: string): Promise<{ error: string | null }> => {
    try {
      console.log('🔄 Kayıt olma başlatılıyor:', email);
      
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const firebaseUser = userCredential.user;

      // Display name güncelle
      if (firstName || lastName) {
        await updateProfile(firebaseUser, {
          displayName: `${firstName || ''} ${lastName || ''}`.trim()
        });
      }

      // Profile oluştur
      const newProfile: Profile = {
        id: firebaseUser.uid,
        first_name: firstName || null,
        last_name: lastName || null,
        avatar_url: null,
        updated_at: new Date().toISOString()
      };

      await setDoc(doc(db, COLLECTIONS.PROFILES, firebaseUser.uid), newProfile);
      setProfile(newProfile);

      console.log('✅ Kayıt başarılı');
      return { error: null };
    } catch (error: any) {
      console.error('❌ Kayıt hatası:', error);
      return { error: error.message };
    }
  };

  // Giriş yapma
  const signIn = async (email: string, password: string): Promise<{ error: string | null }> => {
    try {
      console.log('🔄 Giriş yapılıyor:', email);
      
      await signInWithEmailAndPassword(auth, email, password);
      console.log('✅ Giriş başarılı');
      return { error: null };
    } catch (error: any) {
      console.error('❌ Giriş hatası:', error);
      return { error: error.message };
    }
  };

  // Çıkış yapma
  const signOutUser = async (): Promise<void> => {
    try {
      await signOut(auth);
      console.log('✅ Çıkış başarılı');
    } catch (error) {
      console.error('❌ Çıkış hatası:', error);
    }
  };

  // Şifre sıfırlama
  const resetPassword = async (email: string): Promise<{ error: string | null }> => {
    try {
      await sendPasswordResetEmail(auth, email);
      console.log('✅ Şifre sıfırlama e-postası gönderildi');
      return { error: null };
    } catch (error: any) {
      console.error('❌ Şifre sıfırlama hatası:', error);
      return { error: error.message };
    }
  };

  // Profile güncelleme
  const updateUserProfile = async (updates: Partial<Profile>): Promise<{ error: string | null }> => {
    try {
      if (!user) {
        return { error: 'Kullanıcı giriş yapmamış' };
      }

      const updatedProfile = {
        ...profile,
        ...updates,
        updated_at: new Date().toISOString()
      } as Profile;

      await setDoc(doc(db, COLLECTIONS.PROFILES, user.uid), updatedProfile);
      setProfile(updatedProfile);

      console.log('✅ Profile güncellendi');
      return { error: null };
    } catch (error: any) {
      console.error('❌ Profile güncelleme hatası:', error);
      return { error: error.message };
    }
  };

  return {
    user,
    profile,
    loading,
    signUp,
    signIn,
    signOut: signOutUser,
    resetPassword,
    updateProfile: updateUserProfile
  };
}; 