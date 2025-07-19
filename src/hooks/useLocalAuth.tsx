import React, { useState, useEffect, createContext, useContext } from 'react';

interface LocalUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  createdAt: string;
}

interface LocalAuthContextType {
  user: LocalUser | null;
  loading: boolean;
  signUp: (email: string, password: string, firstName?: string, lastName?: string) => Promise<{ error: any | null }>;
  signIn: (email: string, password: string) => Promise<{ error: any | null }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error: any | null }>;
}

const LocalAuthContext = createContext<LocalAuthContextType | null>(null);

export const useLocalAuth = (): LocalAuthContextType => {
  const context = useContext(LocalAuthContext);
  if (!context) {
    throw new Error('useLocalAuth must be used within a LocalAuthProvider');
  }
  return context;
};

export const LocalAuthProvider = ({ children }: { children: React.ReactNode }): React.ReactElement => {
  const [user, setUser] = useState<LocalUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Local storage'dan kullanıcı bilgisini al
    const savedUser = localStorage.getItem('localAuth_user');
    if (savedUser) {
      try {
        setUser(JSON.parse(savedUser));
      } catch (error) {
        console.error('Local auth user parse error:', error);
        localStorage.removeItem('localAuth_user');
      }
    }
    setLoading(false);
  }, []);

  const signUp = async (email: string, password: string, firstName?: string, lastName?: string): Promise<{ error: any | null }> => {
    try {
      console.log('🔄 Local auth signup başlatılıyor:', { email, firstName, lastName });
      
      // E-posta doğrulaması
      if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
        return { error: { message: 'Geçerli bir e-posta adresi girin.' } };
      }

      // Şifre doğrulaması
      if (!password || password.length < 6) {
        return { error: { message: 'Şifre en az 6 karakter olmalıdır.' } };
      }

      // Kullanıcı zaten var mı kontrol et
      const existingUsers = JSON.parse(localStorage.getItem('localAuth_users') || '[]');
      const existingUser = existingUsers.find((u: LocalUser) => u.email === email);
      
      if (existingUser) {
        return { error: { message: 'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin.' } };
      }

      // Yeni kullanıcı oluştur
      const newUser: LocalUser = {
        id: crypto.randomUUID(),
        email: email.toLowerCase().trim(),
        firstName: firstName?.trim() || 'Kullanıcı',
        lastName: lastName?.trim() || '',
        createdAt: new Date().toISOString()
      };

      // Kullanıcıyı kaydet
      existingUsers.push(newUser);
      localStorage.setItem('localAuth_users', JSON.stringify(existingUsers));
      
      // Şifreyi ayrı kaydet (gerçek uygulamada hash'lenmeli)
      const passwords = JSON.parse(localStorage.getItem('localAuth_passwords') || '{}');
      passwords[newUser.id] = password;
      localStorage.setItem('localAuth_passwords', JSON.stringify(passwords));

      // Oturum aç
      setUser(newUser);
      localStorage.setItem('localAuth_user', JSON.stringify(newUser));

      console.log('✅ Local auth signup başarılı:', newUser);
      return { error: null };
    } catch (error) {
      console.error('❌ Local auth signup hatası:', error);
      return { error: { message: 'Kayıt işlemi başarısız. Lütfen tekrar deneyin.' } };
    }
  };

  const signIn = async (email: string, password: string): Promise<{ error: any | null }> => {
    try {
      console.log('🔐 Local auth signin başlatılıyor:', { email });
      
      // E-posta doğrulaması
      if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
        return { error: { message: 'Geçerli bir e-posta adresi girin.' } };
      }

      // Şifre doğrulaması
      if (!password || password.length < 6) {
        return { error: { message: 'Şifre en az 6 karakter olmalıdır.' } };
      }

      // Kullanıcıyı bul
      const users = JSON.parse(localStorage.getItem('localAuth_users') || '[]');
      const user = users.find((u: LocalUser) => u.email === email.toLowerCase().trim());
      
      if (!user) {
        return { error: { message: 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.' } };
      }

      // Şifreyi kontrol et
      const passwords = JSON.parse(localStorage.getItem('localAuth_passwords') || '{}');
      if (passwords[user.id] !== password) {
        return { error: { message: 'E-posta adresi veya şifre yanlış.' } };
      }

      // Oturum aç
      setUser(user);
      localStorage.setItem('localAuth_user', JSON.stringify(user));

      console.log('✅ Local auth signin başarılı:', user);
      return { error: null };
    } catch (error) {
      console.error('❌ Local auth signin hatası:', error);
      return { error: { message: 'Giriş işlemi başarısız. Lütfen tekrar deneyin.' } };
    }
  };

  const signOut = async (): Promise<void> => {
    try {
      setUser(null);
      localStorage.removeItem('localAuth_user');
      console.log('✅ Local auth signout başarılı');
    } catch (error) {
      console.error('❌ Local auth signout hatası:', error);
    }
  };

  const resetPassword = async (email: string): Promise<{ error: any | null }> => {
    try {
      console.log('📧 Local auth password reset başlatılıyor:', { email });
      
      // E-posta doğrulaması
      if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
        return { error: { message: 'Geçerli bir e-posta adresi girin.' } };
      }

      // Kullanıcıyı bul
      const users = JSON.parse(localStorage.getItem('localAuth_users') || '[]');
      const user = users.find((u: LocalUser) => u.email === email.toLowerCase().trim());
      
      if (!user) {
        return { error: { message: 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.' } };
      }

      // Yeni şifre oluştur (gerçek uygulamada e-posta gönderilir)
      const newPassword = Math.random().toString(36).slice(-8) + '123';
      
      // Şifreyi güncelle
      const passwords = JSON.parse(localStorage.getItem('localAuth_passwords') || '{}');
      passwords[user.id] = newPassword;
      localStorage.setItem('localAuth_passwords', JSON.stringify(passwords));

      console.log('✅ Local auth password reset başarılı. Yeni şifre:', newPassword);
      return { error: null };
    } catch (error) {
      console.error('❌ Local auth password reset hatası:', error);
      return { error: { message: 'Şifre sıfırlama işlemi başarısız. Lütfen tekrar deneyin.' } };
    }
  };

  const value: LocalAuthContextType = {
    user,
    loading,
    signUp,
    signIn,
    signOut,
    resetPassword,
  };

  return (
    <LocalAuthContext.Provider value={value}>
      {children}
    </LocalAuthContext.Provider>
  );
}; 