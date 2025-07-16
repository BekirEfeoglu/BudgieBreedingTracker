import { useState, useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useSecureAuth } from '@/hooks/useSecureAuth';
import { toast } from '@/components/ui/use-toast';
import { ArrowLeft, Mail, Lock, User, Eye, EyeOff } from 'lucide-react';

interface AuthPageProps {
  onBack: () => void;
}

const AuthPage = ({ onBack }: AuthPageProps) => {
  const [mode, setMode] = useState<'login' | 'signup' | 'forgot'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);

  const [typewriterText, setTypewriterText] = useState("");
  const fullTitle = "BudgieBreedingTracker";
  
  const { signIn, signUp, resetPassword, user } = useSecureAuth();



  useEffect(() => {
    let currentIndex = 0;
    setTypewriterText("");
    const interval = setInterval(() => {
      setTypewriterText((prev) => prev + fullTitle[currentIndex]);
      currentIndex++;
      if (currentIndex === fullTitle.length) {
        clearInterval(interval);
      }
    }, 70); // Hız ayarlanabilir
    return () => clearInterval(interval);
  }, []);

  // If user is already authenticated, don't show the auth form
  useEffect(() => {
    if (user) {
      // User is already authenticated, redirecting...
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (mode === 'login') {
        const { error } = await signIn(email, password);
        if (error) {
          toast({
            title: 'Giriş Hatası',
            description: error.message === 'Invalid login credentials' 
              ? 'E-posta veya şifre hatalı' 
              : error.message,
            variant: 'destructive',
          });
        } else {
          toast({
            title: 'Başarılı!',
            description: 'Başarıyla giriş yaptınız.',
          });
          // Navigation will be handled by ProtectedRoute
        }
      } else if (mode === 'signup') {
        const { error } = await signUp(email, password, firstName, lastName);
        if (error) {
          console.error('Kayıt hatası detayları:', error);
          toast({
            title: 'Kayıt Hatası',
            description: error.message || 'Bilinmeyen bir hata oluştu. Lütfen tekrar deneyin.',
            variant: 'destructive',
          });
        } else {
          toast({
            title: 'Kayıt Başarılı!',
            description: 'Hesabınız oluşturuldu. E-posta adresinizi kontrol edin.',
          });
          setMode('login');
        }
      } else if (mode === 'forgot') {
        const { error } = await resetPassword(email);
        if (error) {
          toast({
            title: 'Hata',
            description: error.message,
            variant: 'destructive',
          });
        } else {
          toast({
            title: 'E-posta Gönderildi',
            description: 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
          });
          setMode('login');
        }
      }
    } catch (error) {
      console.error('Auth error:', error);
      toast({
        title: 'Hata',
        description: 'Bir hata oluştu. Lütfen tekrar deneyin.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  // Don't show back button since this is now the entry point
  const showBackButton = false;

  return (
    <div className="min-h-screen bg-gradient-to-br from-budgie-cream via-budgie-warm to-budgie-cream flex items-center justify-center p-4 relative overflow-hidden">
      {/* Background decorative elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-20 left-10 w-20 h-20 budgie-gradient rounded-full opacity-20 animate-bounce-gentle" 
             style={{ animationDelay: '0s', animationDuration: '3s' }}></div>
        <div className="absolute top-40 right-20 w-16 h-16 bg-accent/20 rounded-full animate-bounce-gentle" 
             style={{ animationDelay: '1s', animationDuration: '4s' }}></div>
        <div className="absolute bottom-32 left-1/4 w-12 h-12 bg-primary/20 rounded-full animate-bounce-gentle" 
             style={{ animationDelay: '2s', animationDuration: '5s' }}></div>
      </div>

      <div className="w-full max-w-none relative z-10 p-0 m-0 flex flex-col items-center">
        {/* Animated Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-3 mb-6">
            <div className="w-20 h-20 budgie-gradient rounded-full flex items-center justify-center text-4xl shadow-lg animated-budgie">
              ��
            </div>
          </div>
          
          <div className="mb-4">
            <h1 className="text-xl md:text-2xl animated-title mb-2 text-center whitespace-nowrap w-full max-w-none overflow-x-auto p-0 m-0" style={{letterSpacing: 0}}>
              <span className="typewriter-text w-full whitespace-nowrap max-w-none overflow-x-auto block">{typewriterText}</span>
            </h1>
          </div>
          
          <p className="text-lg text-muted-foreground animated-subtitle">
            Muhabbet kuşlarınızın takibini kolaylaştırın
          </p>
          
          <div className="w-24 h-1 budgie-gradient rounded-full mx-auto mt-4 animated-subtitle" 
               style={{ animationDelay: '0.8s' }}></div>
        </div>

        <Card className="budgie-card p-6 backdrop-blur-sm bg-card/95">
          {showBackButton && (
            <div className="mb-6">
              <Button
                variant="ghost"
                onClick={onBack}
                className="p-0 h-auto hover:bg-transparent text-muted-foreground hover:text-foreground transition-colors"
              >
                <ArrowLeft className="w-4 h-4 mr-2" />
                Ana Sayfaya Dön
              </Button>
            </div>
          )}

          <div className="space-y-4">
            <div className="flex gap-1 p-1 bg-muted rounded-lg">
              <button
                onClick={() => setMode('login')}
                className={`flex-1 py-2 px-3 text-sm font-medium rounded-md transition-all ${
                  mode === 'login'
                    ? 'bg-background shadow-sm text-foreground'
                    : 'text-muted-foreground hover:text-foreground'
                }`}
              >
                Giriş Yap
              </button>
              <button
                onClick={() => setMode('signup')}
                className={`flex-1 py-2 px-3 text-sm font-medium rounded-md transition-all ${
                  mode === 'signup'
                    ? 'bg-background shadow-sm text-foreground'
                    : 'text-muted-foreground hover:text-foreground'
                }`}
              >
                Kayıt Ol
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {mode === 'signup' && (
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="firstName">Ad</Label>
                    <div className="relative">
                      <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="firstName"
                        type="text"
                        placeholder="Adınız"
                        value={firstName}
                        onChange={(e) => setFirstName(e.target.value)}
                        className="pl-10"
                        required
                      />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="lastName">Soyad</Label>
                    <div className="relative">
                      <User className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="lastName"
                        type="text"
                        placeholder="Soyadınız"
                        value={lastName}
                        onChange={(e) => setLastName(e.target.value)}
                        className="pl-10"
                        required
                      />
                    </div>
                  </div>
                </div>
              )}

              <div className="space-y-2">
                <Label htmlFor="email">E-posta</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="ornek@email.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="pl-10"
                    required
                  />
                </div>
              </div>

              {mode !== 'forgot' && (
                <div className="space-y-2">
                  <Label htmlFor="password">Şifre</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Şifreniz"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="pl-10 pr-10"
                      required
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-3 text-muted-foreground hover:text-foreground"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>
              )}

              <Button type="submit" className="w-full budgie-button" disabled={loading}>
                {loading ? 'Lütfen bekleyin...' : 
                 mode === 'login' ? 'Giriş Yap' : 
                 mode === 'signup' ? 'Kayıt Ol' : 
                 'Şifre Sıfırla'}
              </Button>
            </form>

            {mode === 'login' && (
              <div className="text-center">
                <button
                  onClick={() => setMode('forgot')}
                  className="text-sm text-muted-foreground hover:text-primary underline"
                >
                  Şifremi unuttum
                </button>
              </div>
            )}

            {mode === 'forgot' && (
              <div className="text-center">
                <button
                  onClick={() => setMode('login')}
                  className="text-sm text-muted-foreground hover:text-primary underline"
                >
                  Giriş sayfasına dön
                </button>
              </div>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
};

export default AuthPage;
