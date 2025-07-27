import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useAuth } from '@/hooks/useAuth';
import { toast } from '@/components/ui/use-toast';
import { validatePassword } from '@/utils/inputSanitization';
import { Mail, Lock, User, Eye, EyeOff, AlertCircle, Sparkles, Shield, Zap } from 'lucide-react';

// Animasyonlu SVG Muhabbet Kuşu + Yumurta bileşeni
const BudgieLogo = () => (
  <svg
    width="56"
    height="56"
    viewBox="0 0 56 56"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className="budgie-logo"
    style={{ display: 'block' }}
  >
    {/* Gövde */}
    <ellipse cx="28" cy="36" rx="14" ry="16" fill="#A7F3D0" stroke="#059669" strokeWidth="2" />
    {/* Kafa */}
    <circle cx="28" cy="18" r="10" fill="#FDE68A" stroke="#F59E42" strokeWidth="2" />
    {/* Göz */}
    <circle cx="32" cy="18" r="2" fill="#222" />
    {/* Gaga */}
    <polygon points="36,22 32,22 34,26" fill="#F59E42" />
    {/* Kanat (animasyonlu) */}
    <g className="budgie-wing">
      <ellipse cx="18" cy="36" rx="7" ry="12" fill="#6EE7B7" stroke="#059669" strokeWidth="1.5" />
    </g>
    {/* Kuyruk */}
    <rect x="26" y="50" width="4" height="10" rx="2" fill="#2563EB" />
    {/* Yumurta (animasyonlu) */}
    <g className="budgie-egg">
      <ellipse cx="44" cy="44" rx="6" ry="8" fill="#fff" stroke="#cbd5e1" strokeWidth="1.5" />
      <ellipse cx="44" cy="42" rx="2" ry="1" fill="#fef9c3" opacity="0.7" />
    </g>
  </svg>
);

// Uçan arka plan muhabbet kuşu SVG bileşeni (daha canlı renkler, büyük boyut, birine gölge)
const FlyingBudgie = ({ style, className = '', shadow = false }: { style?: React.CSSProperties; className?: string; shadow?: boolean }) => (
  <svg
    width="88"
    height="88"
    viewBox="0 0 56 56"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className={className}
    style={style}
  >
    {shadow && <ellipse cx="28" cy="70" rx="18" ry="6" fill="#000" opacity="0.18" />}
    <ellipse cx="28" cy="36" rx="14" ry="16" fill="#34D399" />
    <circle cx="28" cy="18" r="10" fill="#FBBF24" />
    <circle cx="32" cy="18" r="2.2" fill="#222" />
    <polygon points="36,22 32,22 34,26" fill="#F59E42" />
    <ellipse cx="18" cy="36" rx="7" ry="12" fill="#10B981" />
    <rect x="26" y="50" width="4" height="12" rx="2" fill="#2563EB" />
    <g>
      <ellipse cx="44" cy="44" rx="7" ry="9" fill="#fff" stroke="#fbbf24" strokeWidth="1.5" />
      <ellipse cx="44" cy="42" rx="2.5" ry="1.2" fill="#fde68a" opacity="0.9" />
    </g>
  </svg>
);

const LoginPage = () => {
  const [mode, setMode] = useState<'login' | 'signup' | 'forgot'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [showAll, setShowAll] = useState(false);
  const [displayedText, setDisplayedText] = useState('');
  const [currentCharIndex, setCurrentCharIndex] = useState(0);
  const [emailError, setEmailError] = useState('');
  
  const emailRef = useRef<HTMLInputElement>(null);
  
  const { signIn, signUp, resetPassword, user } = useAuth();
  const navigate = useNavigate();

  const appName = 'BudgieBreedingTracker';

    // Animasyonlu fade-in ve typewriter
  useEffect(() => {
    const timer = setTimeout(() => setShowAll(true), 200);
    return () => clearTimeout(timer);
  }, []);

  // Typewriter animasyonu
  useEffect(() => {
    if (!showAll) return;
    let timeout: NodeJS.Timeout;
    if (currentCharIndex < appName.length && displayedText.length <= appName.length) {
      timeout = setTimeout(() => {
        setDisplayedText(appName.slice(0, currentCharIndex + 1));
        setCurrentCharIndex(currentCharIndex + 1);
      }, 120);
    } else if (currentCharIndex === appName.length) {
      timeout = setTimeout(() => {
        setCurrentCharIndex(-1);
      }, 2000);
    } else if (currentCharIndex < 0 && displayedText.length > 0) {
      timeout = setTimeout(() => {
        setDisplayedText(appName.slice(0, displayedText.length - 1));
        if (displayedText.length - 1 === 0) {
          setCurrentCharIndex(0);
        }
      }, 60);
    }
    return () => clearTimeout(timeout);
  }, [showAll, currentCharIndex, displayedText, appName]);

  useEffect(() => {
    emailRef.current?.focus();
  }, []);

  useEffect(() => {
    if (user) {
      navigate('/', { replace: true });
    }
  }, [user, navigate]);

  const getErrorMessage = (error: unknown) => {
    if (error && typeof error === 'object' && 'message' in error) {
      const errorMessage = (error as any).message;
      
      if (errorMessage.includes('email rate limit exceeded')) {
        return 'Bu e-posta adresi ile çok fazla kayıt denemesi yapıldı. Lütfen 1 saat bekleyin veya farklı bir e-posta adresi kullanın.';
      }
      if (errorMessage.includes('Too many requests')) {
        return 'Çok fazla deneme yaptınız. Lütfen bir süre bekleyin.';
      }
      if (errorMessage.includes('User not found')) {
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      }
      if (errorMessage.includes('Invalid email')) {
        return 'Geçersiz e-posta adresi formatı.';
      }
      if (errorMessage.includes('Weak password')) {
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      }
      if (errorMessage.includes('User already registered')) {
        return 'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin.';
      }
      if (errorMessage.includes('Unable to validate email address')) {
        return 'E-posta adresi doğrulanamadı. Lütfen geçerli bir e-posta adresi girin.';
      }
      if (errorMessage.includes('Signup disabled')) {
        return 'Yeni hesap oluşturma şu anda devre dışı.';
      }
      if (errorMessage.includes('Signup not allowed')) {
        return 'Yeni hesap oluşturmaya izin verilmiyor.';
      }
      if (errorMessage.includes('Password should be at least')) {
        return 'Şifre en az 6 karakter olmalıdır.';
      }
      if (errorMessage.includes('Password should contain')) {
        return 'Şifre en az 2 farklı karakter türü içermelidir (büyük harf, küçük harf, rakam, özel karakter).';
      }
      
      return errorMessage;
    }
    if (typeof error === 'string') return error;
    return 'Bilinmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setEmailError('');
    
    console.log('🔄 Form gönderiliyor:', { mode, email, firstName, lastName });
    
    if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      setEmailError('Geçerli bir e-posta adresi giriniz.');
      setLoading(false);
      return;
    }
    
    try {
      if (mode === 'login') {
        console.log('🔐 Giriş işlemi başlatılıyor...');
        const { error } = await signIn(email, password);
        if (error) {
          console.error('❌ Giriş hatası:', error);
          toast({ title: 'Giriş Yapılamadı', description: getErrorMessage(error), variant: 'destructive' });
        } else {
          console.log('✅ Giriş başarılı!');
          toast({ title: 'Hoş Geldiniz! 🎉', description: 'Başarıyla giriş yaptınız.' });
          navigate('/', { replace: true });
        }
      } else if (mode === 'signup') {
        console.log('📝 Kayıt işlemi başlatılıyor...');
        
        const passwordValidation = validatePassword(password);
        if (!passwordValidation.isValid) {
          console.error('❌ Şifre geçersiz:', passwordValidation.errors);
          toast({ title: 'Şifre Geçersiz', description: passwordValidation.errors[0], variant: 'destructive' });
          return;
        }
        
        console.log('✅ Şifre doğrulaması geçti');
        const { error } = await signUp(email, password, firstName, lastName);
        
        if (error) {
          console.error('❌ Kayıt hatası:', error);
          console.error('❌ Hata detayları:', {
            message: error.message,
            name: error.name,
            stack: error.stack
          });
          
          // E-posta onayı gerekli mesajı başarı mesajı olarak göster
          if (error.message.includes('E-posta onayı gerekli')) {
            console.log('✅ Kayıt başarılı - E-posta onayı gerekli');
            console.log('📧 Kullanıcıya e-posta onayı mesajı gösteriliyor');
            toast({ title: 'Hesap Oluşturuldu! 📧', description: error.message });
            setMode('login');
          } else {
            console.log('❌ Gerçek kayıt hatası - Kullanıcıya hata mesajı gösteriliyor');
            toast({ title: 'Hesap Oluşturulamadı', description: getErrorMessage(error), variant: 'destructive' });
          }
        } else {
          console.log('✅ Kayıt başarılı!');
          toast({ title: 'Hesap Oluşturuldu! 📧', description: 'E-posta adresinize doğrulama bağlantısı gönderildi. Lütfen e-posta kutunuzu kontrol edin.' });
          setMode('login');
        }
      } else if (mode === 'forgot') {
        console.log('📧 Şifre sıfırlama işlemi başlatılıyor...');
        const { error } = await resetPassword(email);
        if (error) {
          console.error('❌ Şifre sıfırlama hatası:', error);
          toast({ title: 'E-posta Gönderilemedi', description: getErrorMessage(error), variant: 'destructive' });
        } else {
          console.log('✅ Şifre sıfırlama e-postası gönderildi');
          toast({ title: 'E-posta Gönderildi 📬', description: 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.' });
          setMode('login');
        }
      }
    } catch (error) {
      console.error('💥 Beklenmeyen hata:', error);
      console.error('💥 Hata detayları:', {
        name: error instanceof Error ? error.name : 'Unknown',
        message: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : 'No stack'
      });
      toast({ title: 'Bağlantı Hatası', description: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 via-indigo-100 to-purple-100 relative overflow-hidden">
      {/* Animasyonlu arka plan şekilleri */}
      <div className="absolute inset-0 pointer-events-none hidden sm:block">
        <div className="absolute top-10 left-1/4 w-60 h-60 bg-gradient-to-br from-blue-400/20 to-purple-400/20 rounded-full blur-2xl animate-pulse-slow"></div>
        <div className="absolute bottom-10 right-1/4 w-72 h-72 bg-gradient-to-br from-indigo-400/20 to-blue-400/20 rounded-full blur-2xl animate-pulse-slow"></div>
        <div className="absolute top-1/2 left-1/2 w-96 h-96 -translate-x-1/2 -translate-y-1/2 bg-gradient-to-br from-purple-400/10 to-pink-400/10 rounded-full blur-3xl animate-float-slow"></div>
        <FlyingBudgie className="flying-budgie flying-budgie-1" style={{ top: '12%', left: '-12%' }} shadow />
        <FlyingBudgie className="flying-budgie flying-budgie-2" style={{ top: '58%', left: '-18%' }} />
        <FlyingBudgie className="flying-budgie flying-budgie-3" style={{ top: '32%', left: '-22%' }} />
      </div>
      <div className="relative z-10 w-full max-w-xs sm:max-w-md md:max-w-lg">
        <Card className={`p-4 sm:p-6 md:p-10 shadow-2xl border-0 bg-white/90 backdrop-blur-xl transition-all duration-700 ${showAll ? 'animate-fade-in-down' : 'opacity-0 translate-y-10'}`}>
          <div className="flex flex-col items-center gap-4 sm:gap-6">
            {/* Logo ve başlık */}
                        <div className={`flex flex-col items-center gap-2 transition-all duration-700 ${showAll ? 'animate-fade-in-up' : 'opacity-0 translate-y-10'}`}>
              <div className="w-14 h-14 sm:w-16 sm:h-16 bg-gradient-to-br from-blue-600 to-indigo-700 rounded-2xl shadow-xl flex items-center justify-center mb-2 animate-float-slow">
                <BudgieLogo />
              </div>
              <h1 className="text-sm xs:text-base sm:text-lg md:text-xl lg:text-2xl font-bold text-gray-900 tracking-tight text-center w-full max-w-[280px] sm:max-w-sm md:max-w-md mx-auto overflow-hidden leading-tight break-words [overflow-wrap:anywhere] px-2">
                <span className="bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 bg-clip-text text-transparent block break-words [overflow-wrap:anywhere]">
                  {displayedText}
                  <span className="inline-block w-0.5 h-4 sm:h-5 md:h-6 bg-blue-600 ml-1 align-middle animate-pulse"></span>
                </span>
              </h1>
              <p className="text-base text-gray-600 text-center mt-2">Muhabbet kuşlarınızın üretim sürecini profesyonel şekilde takip edin</p>
            </div>
            {/* Özellikler */}
            <div className="flex flex-col gap-2 w-full max-w-xs mx-auto">
              <div className="flex items-center gap-2 text-gray-700 text-sm">
                <Shield className="w-4 h-4 text-green-600" />
                Güvenli ve şeffaf takip sistemi
              </div>
              <div className="flex items-center gap-2 text-gray-700 text-sm">
                <Zap className="w-4 h-4 text-blue-600" />
                Hızlı ve kolay kullanım
              </div>
              <div className="flex items-center gap-2 text-gray-700 text-sm">
                <Sparkles className="w-4 h-4 text-purple-600" />
                Detaylı analiz ve raporlama
              </div>
            </div>
            {/* Form */}
            <form onSubmit={handleSubmit} className="w-full space-y-5 mt-2">
              {mode === 'signup' && (
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <Label htmlFor="firstName" className="text-sm font-semibold text-gray-700">Ad</Label>
                    <div className="relative">
                      <User className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                      <input
                        id="firstName"
                        type="text"
                        placeholder="Adınız"
                        value={firstName}
                        onChange={(e) => setFirstName(e.target.value)}
                        className="pl-10 h-11 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 rounded-lg text-gray-900 bg-white"
                        style={{
                          color: '#111827',
                          backgroundColor: '#ffffff',
                          WebkitTextFillColor: '#111827',
                          caretColor: '#111827',
                          fontSize: '16px',
                          WebkitAppearance: 'none',
                          MozAppearance: 'textfield',
                          appearance: 'none',
                          WebkitTapHighlightColor: 'transparent',
                          WebkitUserSelect: 'text',
                          MozUserSelect: 'text',
                          msUserSelect: 'text',
                          userSelect: 'text',
                          width: '100%',
                          display: 'block',
                          boxSizing: 'border-box'
                        }}
                        required
                      />
                    </div>
                  </div>
                  <div className="space-y-1">
                    <Label htmlFor="lastName" className="text-sm font-semibold text-gray-700">Soyad</Label>
                    <div className="relative">
                      <User className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                      <input
                        id="lastName"
                        type="text"
                        placeholder="Soyadınız"
                        value={lastName}
                        onChange={(e) => setLastName(e.target.value)}
                        className="pl-10 h-11 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 rounded-lg text-gray-900 bg-white"
                        style={{
                          color: '#111827',
                          backgroundColor: '#ffffff',
                          WebkitTextFillColor: '#111827',
                          caretColor: '#111827',
                          fontSize: '16px',
                          WebkitAppearance: 'none',
                          MozAppearance: 'textfield',
                          appearance: 'none',
                          WebkitTapHighlightColor: 'transparent',
                          WebkitUserSelect: 'text',
                          MozUserSelect: 'text',
                          msUserSelect: 'text',
                          userSelect: 'text',
                          width: '100%',
                          display: 'block',
                          boxSizing: 'border-box'
                        }}
                        required
                      />
                    </div>
                  </div>
                </div>
              )}
              <div className="space-y-1">
                <Label htmlFor="email" className="text-sm font-semibold text-gray-700">E-posta Adresi</Label>
                <div>
                  <input
                    ref={emailRef}
                    id="email"
                    type="text"
                    inputMode="email"
                    autoComplete="email"
                    autoCorrect="off"
                    autoCapitalize="none"
                    spellCheck={false}
                    placeholder="ornek@email.com"
                    value={email}
                    onChange={e => {
                      setEmail(e.target.value);
                      if (emailError) setEmailError('');
                    }}
                    aria-label="E-posta Adresi"
                    aria-invalid={!!emailError}
                    style={{
                      width: '100%',
                      fontSize: 16,
                      background: '#fff',
                      color: '#111',
                      border: emailError ? '1px solid #f00' : '1px solid #ccc',
                      borderRadius: 4,
                      padding: 12,
                      boxSizing: 'border-box'
                    }}
                    required
                  />
                  {emailError && (
                    <div style={{ color: '#f00', fontSize: 12, marginTop: 4 }}>{emailError}</div>
                  )}
                </div>
              </div>
              {mode !== 'forgot' && (
                <div className="space-y-1">
                  <Label htmlFor="password" className="text-sm font-semibold text-gray-700">Şifre</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                    <input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      placeholder={mode === 'signup' ? 'En az 6 karakter' : 'Şifreniz'}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="pl-10 pr-10 h-11 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 rounded-lg text-gray-900 bg-white"
                      style={{
                        color: '#111827',
                        backgroundColor: '#ffffff',
                        WebkitTextFillColor: '#111827',
                        caretColor: '#111827',
                        fontSize: '16px',
                        WebkitAppearance: 'none',
                        MozAppearance: 'textfield',
                        appearance: 'none',
                        WebkitTapHighlightColor: 'transparent',
                        WebkitUserSelect: 'text',
                        MozUserSelect: 'text',
                        msUserSelect: 'text',
                        userSelect: 'text',
                        width: '100%',
                        display: 'block',
                        boxSizing: 'border-box'
                      }}
                      required
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-3 text-gray-400 hover:text-gray-600 transition-colors"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  {mode === 'signup' && password.length > 0 && password.length < 6 && (
                    <div className="flex items-center gap-2 text-xs text-amber-600 mt-1">
                      <AlertCircle className="h-4 w-4" />
                      <span>Şifre en az 6 karakter olmalı</span>
                    </div>
                  )}
                </div>
              )}
              {/* Tab Navigation */}
              <div className="flex gap-1 p-1 bg-gray-100 rounded-xl mb-2 mt-2">
                <button
                  type="button"
                  onClick={() => setMode('login')}
                  className={`flex-1 py-2 px-4 text-sm font-semibold rounded-lg transition-all duration-300 ${mode === 'login' ? 'bg-white shadow text-gray-900' : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'}`}
                >
                  Giriş Yap
                </button>
                <button
                  type="button"
                  onClick={() => setMode('signup')}
                  className={`flex-1 py-2 px-4 text-sm font-semibold rounded-lg transition-all duration-300 ${mode === 'signup' ? 'bg-white shadow text-gray-900' : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'}`}
                >
                  Kayıt Ol
                </button>
              </div>
              <Button 
                type="submit" 
                className="w-full h-11 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-semibold rounded-lg transition-all duration-300 hover:shadow-lg" 
                disabled={loading}
              >
                {loading ? (
                  <div className="flex items-center gap-2">
                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                    <span>Lütfen bekleyin...</span>
                  </div>
                ) : (
                  mode === 'login' ? 'Giriş Yap' : 
                  mode === 'signup' ? 'Hesap Oluştur' : 
                  'Şifre Sıfırla'
                )}
              </Button>
              <div className="mt-2 text-center">
                {mode === 'login' && (
                  <button
                    type="button"
                    onClick={() => setMode('forgot')}
                    className="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors"
                  >
                    Şifremi unuttum
                  </button>
                )}
                {mode === 'forgot' && (
                  <button
                    type="button"
                    onClick={() => setMode('login')}
                    className="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors"
                  >
                    ← Giriş sayfasına dön
                  </button>
                )}
              </div>
            </form>
            {/* Güvenlik */}
            <div className="mt-4 p-3 bg-gray-50 rounded-lg w-full flex items-center gap-3 justify-center">
              <Shield className="w-5 h-5 text-green-600" />
              <div className="text-xs text-gray-600">
                <p className="font-medium">Güvenli Bağlantı</p>
                <p>Verileriniz SSL ile şifrelenerek korunmaktadır</p>
              </div>
            </div>
          </div>
        </Card>
      </div>
      {/* Animasyonlar için ek CSS */}
      <style>{`
        @keyframes fade-in-down { 0% { opacity: 0; transform: translateY(40px); } 100% { opacity: 1; transform: translateY(0); } }
        .animate-fade-in-down { animation: fade-in-down 0.8s cubic-bezier(.4,0,.2,1) both; }
        @keyframes fade-in-up { 0% { opacity: 0; transform: translateY(-40px); } 100% { opacity: 1; transform: translateY(0); } }
        .animate-fade-in-up { animation: fade-in-up 0.8s cubic-bezier(.4,0,.2,1) both; }
        @keyframes pulse-slow { 0%, 100% { opacity: 0.7; } 50% { opacity: 1; } }
        .animate-pulse-slow { animation: pulse-slow 4s ease-in-out infinite; }
        @keyframes float-slow { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-16px); } }
        .animate-float-slow { animation: float-slow 6s ease-in-out infinite; }
        .budgie-wing { transform-origin: 18px 36px; animation: budgie-flap 1.2s infinite cubic-bezier(.4,0,.2,1); }
        @keyframes budgie-flap { 0%,100% { transform: rotate(-10deg); } 50% { transform: rotate(20deg); } }
        .budgie-egg { transform-origin: 44px 44px; animation: budgie-egg-wobble 2.2s infinite cubic-bezier(.4,0,.2,1); }
        @keyframes budgie-egg-wobble { 0%,100% { transform: rotate(-6deg) scale(1); } 10% { transform: rotate(6deg) scale(1.05); } 20% { transform: rotate(-4deg) scale(1.02); } 30% { transform: rotate(4deg) scale(1.04); } 40% { transform: rotate(-2deg) scale(1.01); } 50% { transform: rotate(2deg) scale(1.03); } 60% { transform: rotate(0deg) scale(1); } }
        .typewriter-cursor { display:inline-block; width:2px; height:2em; background:#2563eb; margin-left:2px; vertical-align:middle; animation: blink-cursor 1s steps(2) infinite; border-radius:1px; }
        @keyframes blink-cursor { 0%,100% { opacity:1; } 50% { opacity:0; } }
        .flying-budgie { position: absolute; opacity: 0.3; z-index: 1; pointer-events: none; filter: drop-shadow(0 2px 8px #22d3ee22); }
        .flying-budgie-1 { animation: budgie-fly-curve 16s linear infinite; animation-delay: 0s; }
        .flying-budgie-2 { animation: budgie-fly-zigzag 21s linear infinite; animation-delay: 3s; transform: scale(0.95) rotate(-8deg); }
        .flying-budgie-3 { animation: budgie-fly-wave 25s linear infinite; animation-delay: 7s; transform: scale(1.15) rotate(10deg); }
        @keyframes budgie-fly-curve { 0% { left: -12%; top: 12%; } 20% { top: 10%; } 40% { top: 16%; } 60% { top: 8%; } 80% { top: 14%; } 100% { left: 112%; top: 12%; } }
        @keyframes budgie-fly-zigzag { 0% { left: -18%; top: 58%; } 10% { top: 54%; } 20% { top: 62%; } 30% { top: 56%; } 40% { top: 60%; } 50% { top: 58%; } 60% { top: 62%; } 70% { top: 54%; } 80% { top: 60%; } 100% { left: 112%; top: 58%; } }
        @keyframes budgie-fly-wave { 0% { left: -22%; top: 32%; } 15% { top: 28%; } 30% { top: 36%; } 45% { top: 30%; } 60% { top: 38%; } 75% { top: 34%; } 100% { left: 112%; top: 32%; } }
      `}</style>
    </div>
  );
};

export default LoginPage;
