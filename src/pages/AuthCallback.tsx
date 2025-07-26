import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../integrations/supabase/client'
import { useToast } from '../hooks/use-toast'
import { Button } from '../components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card'
import { CheckCircle, XCircle, Loader2 } from 'lucide-react'

export default function AuthCallback() {
  const navigate = useNavigate()
  const { toast } = useToast()
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [message, setMessage] = useState('Giriş yapılıyor...')

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        setStatus('loading')
        setMessage('Oturum doğrulanıyor...')

        // URL'den parametreleri al
        const urlParams = new URLSearchParams(window.location.search)
        const token = urlParams.get('token')
        const type = urlParams.get('type')
        const error = urlParams.get('error')
        const errorDescription = urlParams.get('error_description')

        // Hata varsa
        if (error) {
          console.error('Auth error:', error, errorDescription)
          setStatus('error')
          setMessage(errorDescription || 'Giriş işlemi başarısız oldu.')
          return
        }

        // Session'ı kontrol et
        const { data, error: sessionError } = await supabase.auth.getSession()
        
        if (sessionError) {
          console.error('Session error:', sessionError)
          setStatus('error')
          setMessage('Oturum doğrulanamadı.')
          return
        }

        if (data.session) {
          setStatus('success')
          setMessage('Email adresiniz başarıyla onaylandı!')
          
          toast({
            title: "Başarılı",
            description: "Hesabınız başarıyla onaylandı ve giriş yapıldı.",
          })

          // 2 saniye sonra dashboard'a yönlendir
          setTimeout(() => {
            navigate('/dashboard')
          }, 2000)
        } else {
          // Session yoksa login sayfasına yönlendir
          setStatus('error')
          setMessage('Oturum bulunamadı. Lütfen tekrar giriş yapın.')
          
          setTimeout(() => {
            navigate('/login')
          }, 3000)
        }
      } catch (error) {
        console.error('Unexpected error:', error)
        setStatus('error')
        setMessage('Beklenmeyen bir hata oluştu.')
        
        setTimeout(() => {
          navigate('/login')
        }, 3000)
      }
    }

    handleAuthCallback()
  }, [navigate, toast])

  const handleRetry = () => {
    window.location.reload()
  }

  const handleGoToLogin = () => {
    navigate('/login')
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-4">
            {status === 'loading' && (
              <Loader2 className="h-12 w-12 text-blue-600 animate-spin" />
            )}
            {status === 'success' && (
              <CheckCircle className="h-12 w-12 text-green-600" />
            )}
            {status === 'error' && (
              <XCircle className="h-12 w-12 text-red-600" />
            )}
          </div>
          <CardTitle className="text-xl">
            {status === 'loading' && 'Giriş Yapılıyor'}
            {status === 'success' && 'Başarılı!'}
            {status === 'error' && 'Hata Oluştu'}
          </CardTitle>
          <CardDescription>
            {message}
          </CardDescription>
        </CardHeader>
        <CardContent className="text-center space-y-4">
          {status === 'loading' && (
            <div className="space-y-2">
              <div className="h-2 bg-gray-200 rounded-full">
                <div className="h-2 bg-blue-600 rounded-full animate-pulse"></div>
              </div>
              <p className="text-sm text-gray-600">Lütfen bekleyin...</p>
            </div>
          )}
          
          {status === 'success' && (
            <div className="space-y-4">
              <p className="text-green-600 font-medium">
                Yönlendiriliyorsunuz...
              </p>
              <div className="h-2 bg-gray-200 rounded-full">
                <div className="h-2 bg-green-600 rounded-full animate-pulse"></div>
              </div>
            </div>
          )}
          
          {status === 'error' && (
            <div className="space-y-4">
              <p className="text-red-600 font-medium">
                Bir sorun oluştu
              </p>
              <div className="flex flex-col space-y-2">
                <Button onClick={handleRetry} variant="outline" className="w-full">
                  Tekrar Dene
                </Button>
                <Button onClick={handleGoToLogin} className="w-full">
                  Giriş Sayfasına Git
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
} 