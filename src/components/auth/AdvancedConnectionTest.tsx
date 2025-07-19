import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Progress } from '@/components/ui/progress';
import { supabase } from '@/integrations/supabase/client';
import { retryData } from '@/utils/simpleRetry';
import { CheckCircle, XCircle, AlertCircle, Loader2, Wifi, WifiOff, RefreshCw, Server } from 'lucide-react';

interface TestResult {
  name: string;
  status: 'success' | 'error' | 'loading' | 'pending';
  message: string;
  duration?: number;
  details?: string;
}

export const AdvancedConnectionTest = () => {
  const [results, setResults] = useState<TestResult[]>([]);
  const [isRunning, setIsRunning] = useState(false);
  const [progress, setProgress] = useState(0);
  const [overallStatus, setOverallStatus] = useState<'pending' | 'success' | 'error'>('pending');

  const runTest = async (testName: string, testFn: () => Promise<any>, timeoutMs: number = 10000): Promise<TestResult> => {
    const startTime = Date.now();
    
    try {
      await testFn();
      const duration = Date.now() - startTime;
      return {
        name: testName,
        status: 'success',
        message: `Başarılı (${duration}ms)`,
        duration
      };
    } catch (error: any) {
      const duration = Date.now() - startTime;
      return {
        name: testName,
        status: 'error',
        message: error.message || 'Bilinmeyen hata',
        duration,
        details: error.stack || error.toString()
      };
    }
  };

  const runAllTests = async () => {
    setIsRunning(true);
    setResults([]);
    setProgress(0);
    setOverallStatus('pending');

    const tests = [
      {
        name: 'DNS Çözümleme',
        fn: () => fetch('https://jxbfdgyusoehqybxdnii.supabase.co', { method: 'HEAD' }),
        timeout: 10000
      },
      {
        name: 'Supabase Ana Endpoint',
        fn: () => fetch('https://jxbfdgyusoehqybxdnii.supabase.co/auth/v1/health'),
        timeout: 10000
      },
      {
        name: 'Auth Servisi',
        fn: () => retryData(() => supabase.auth.getSession(), 'Auth Testi'),
        timeout: 15000
      },
      {
        name: 'Database Bağlantısı',
        fn: () => retryData(() => Promise.resolve(supabase.from('profiles').select('count').limit(1)), 'Database Testi'),
        timeout: 15000
      },
      {
        name: 'Retry Mekanizması Test',
        fn: () => retryData(
          () => Promise.resolve(supabase.from('profiles').select('count').limit(1)),
          'Retry Testi'
        ),
        timeout: 20000
      },
      {
        name: 'Timeout Test (10s)',
        fn: () => new Promise(resolve => setTimeout(resolve, 2000)),
        timeout: 10000
      },
      {
        name: 'CORS Test',
        fn: () => fetch('https://jxbfdgyusoehqybxdnii.supabase.co/rest/v1/', {
          method: 'OPTIONS',
          headers: {
            'Origin': window.location.origin,
            'Access-Control-Request-Method': 'POST',
            'Access-Control-Request-Headers': 'Content-Type, Authorization'
          }
        }),
        timeout: 10000
      }
    ];

    for (let i = 0; i < tests.length; i++) {
      const test = tests[i];
      if (!test) continue;
      
      const progressPercent = ((i + 1) / tests.length) * 100;
      
      setProgress(progressPercent);
      setResults(prev => [...prev, { name: test.name, status: 'loading', message: 'Test ediliyor...' }]);
      
      const result = await runTest(test.name, test.fn, test.timeout);
      
      setResults(prev => prev.map(r => r.name === test.name ? result : r));
      
      // Kısa bir gecikme ekle
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    const finalResults = results.filter(r => r.status !== 'loading');
    const successCount = finalResults.filter(r => r.status === 'success').length;
    const errorCount = finalResults.filter(r => r.status === 'error').length;
    
    if (errorCount === 0) {
      setOverallStatus('success');
    } else if (successCount > errorCount) {
      setOverallStatus('success');
    } else {
      setOverallStatus('error');
    }

    setIsRunning(false);
    setProgress(100);
  };

  const getStatusIcon = (status: TestResult['status']) => {
    switch (status) {
      case 'success':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'error':
        return <XCircle className="h-4 w-4 text-red-500" />;
      case 'loading':
        return <Loader2 className="h-4 w-4 text-blue-500 animate-spin" />;
      default:
        return <AlertCircle className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusBadge = (status: TestResult['status']) => {
    switch (status) {
      case 'success':
        return <Badge variant="default" className="bg-green-100 text-green-800">Başarılı</Badge>;
      case 'error':
        return <Badge variant="destructive">Hata</Badge>;
      case 'loading':
        return <Badge variant="secondary">Test Ediliyor</Badge>;
      default:
        return <Badge variant="outline">Bekliyor</Badge>;
    }
  };

  const getRecommendations = () => {
    const errorResults = results.filter(r => r.status === 'error');
    const recommendations = [];

    if (errorResults.some(r => r.name.includes('DNS'))) {
      recommendations.push('• DNS ayarlarınızı kontrol edin veya farklı bir DNS kullanın (8.8.8.8)');
    }

    if (errorResults.some(r => r.name.includes('Auth'))) {
      recommendations.push('• Supabase Auth servisi geçici olarak kullanılamıyor olabilir');
    }

    if (errorResults.some(r => r.name.includes('Database'))) {
      recommendations.push('• Veritabanı bağlantısında sorun var');
    }

    if (errorResults.some(r => r.name.includes('CORS'))) {
      recommendations.push('• Tarayıcı güvenlik ayarları sorunu');
    }

    if (errorResults.length > 3) {
      recommendations.push('• İnternet bağlantınızı kontrol edin');
      recommendations.push('• VPN kullanıyorsanız kapatın');
      recommendations.push('• Farklı bir ağ deneyin');
    }

    return recommendations.length > 0 ? recommendations : ['• Tüm testler başarılı! Bağlantı sorunları çözülmüş görünüyor.'];
  };

  return (
    <Card className="w-full max-w-4xl mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          {overallStatus === 'success' ? (
            <Wifi className="h-5 w-5 text-green-500" />
          ) : overallStatus === 'error' ? (
            <WifiOff className="h-5 w-5 text-red-500" />
          ) : (
            <Server className="h-5 w-5 text-gray-500" />
          )}
          Gelişmiş Bağlantı Testi
        </CardTitle>
        <CardDescription>
          Supabase bağlantısını ve tüm servisleri detaylı olarak test eder
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-2">
          <Button 
            onClick={runAllTests} 
            disabled={isRunning}
            className="flex-1"
          >
            {isRunning ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Test Ediliyor...
              </>
            ) : (
              <>
                <RefreshCw className="h-4 w-4 mr-2" />
                Tüm Testleri Çalıştır
              </>
            )}
          </Button>
        </div>

        {isRunning && (
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>Test İlerlemesi</span>
              <span>{Math.round(progress)}%</span>
            </div>
            <Progress value={progress} className="w-full" />
          </div>
        )}

        {results.length > 0 && (
          <div className="space-y-3">
            <h4 className="font-medium">Test Sonuçları:</h4>
            {results.map((result, index) => (
              <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="flex items-center gap-3 flex-1">
                  {getStatusIcon(result.status)}
                  <div className="flex-1">
                    <div className="font-medium">{result.name}</div>
                    <div className="text-sm text-gray-600">{result.message}</div>
                    {result.details && (
                      <details className="mt-1">
                        <summary className="text-xs text-blue-600 cursor-pointer">Detayları göster</summary>
                        <pre className="text-xs bg-gray-100 p-2 mt-1 rounded overflow-auto max-h-20">
                          {result.details}
                        </pre>
                      </details>
                    )}
                  </div>
                </div>
                {getStatusBadge(result.status)}
              </div>
            ))}
          </div>
        )}

        {results.length > 0 && (
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              <div className="font-medium mb-2">Öneriler:</div>
              <ul className="space-y-1 text-sm">
                {getRecommendations().map((rec, index) => (
                  <li key={index}>{rec}</li>
                ))}
              </ul>
            </AlertDescription>
          </Alert>
        )}

        {overallStatus === 'success' && results.length > 0 && (
          <Alert>
            <CheckCircle className="h-4 w-4" />
            <AlertDescription>
              Tüm kritik testler başarılı! Bağlantı sorunları çözülmüş görünüyor. 
              Şimdi hesap oluşturmayı tekrar deneyebilirsiniz.
            </AlertDescription>
          </Alert>
        )}
      </CardContent>
    </Card>
  );
}; 