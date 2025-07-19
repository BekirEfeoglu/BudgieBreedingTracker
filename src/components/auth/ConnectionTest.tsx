import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { supabase } from '@/integrations/supabase/client';
import { retryData } from '@/utils/simpleRetry';
import { CheckCircle, XCircle, AlertCircle, Loader2, Wifi, WifiOff } from 'lucide-react';

interface TestResult {
  name: string;
  status: 'success' | 'error' | 'loading' | 'pending';
  message: string;
  duration?: number;
}

export const ConnectionTest = () => {
  const [results, setResults] = useState<TestResult[]>([]);
  const [isRunning, setIsRunning] = useState(false);

  const runTest = async (testName: string, testFn: () => Promise<any>): Promise<TestResult> => {
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
        duration
      };
    }
  };

  const runAllTests = async () => {
    setIsRunning(true);
    setResults([]);

    const tests = [
      {
        name: 'Supabase Bağlantısı',
        fn: () => retryData(() => Promise.resolve(supabase.from('profiles').select('count').limit(1)), 'Bağlantı Testi')
      },
      {
        name: 'Auth Servisi',
        fn: () => retryData(() => supabase.auth.getSession(), 'Auth Testi')
      },
      {
        name: 'Timeout Test (5s)',
        fn: () => new Promise(resolve => setTimeout(resolve, 1000))
      },
      {
        name: 'Retry Test',
        fn: () => retryData(
          () => Promise.resolve(supabase.from('profiles').select('count').limit(1)),
          'Retry Testi'
        )
      }
    ];

    for (const test of tests) {
      setResults(prev => [...prev, { name: test.name, status: 'loading', message: 'Test ediliyor...' }]);
      
      const result = await runTest(test.name, test.fn);
      
      setResults(prev => prev.map(r => r.name === test.name ? result : r));
      
      // Kısa bir gecikme ekle
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    setIsRunning(false);
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

  const overallStatus = results.length > 0 
    ? results.every(r => r.status === 'success') ? 'success' : 'error'
    : 'pending';

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          {overallStatus === 'success' ? (
            <Wifi className="h-5 w-5 text-green-500" />
          ) : overallStatus === 'error' ? (
            <WifiOff className="h-5 w-5 text-red-500" />
          ) : (
            <Wifi className="h-5 w-5 text-gray-500" />
          )}
          Bağlantı Testi
        </CardTitle>
        <CardDescription>
          Supabase bağlantısını ve servislerini test eder
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
              'Tüm Testleri Çalıştır'
            )}
          </Button>
        </div>

        {results.length > 0 && (
          <div className="space-y-3">
            <h4 className="font-medium">Test Sonuçları:</h4>
            {results.map((result, index) => (
              <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                <div className="flex items-center gap-3">
                  {getStatusIcon(result.status)}
                  <div>
                    <div className="font-medium">{result.name}</div>
                    <div className="text-sm text-gray-600">{result.message}</div>
                  </div>
                </div>
                {getStatusBadge(result.status)}
              </div>
            ))}
          </div>
        )}

        {overallStatus === 'error' && results.length > 0 && (
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              Bazı testler başarısız oldu. Bu, 504 hatası almanızın nedeni olabilir. 
              Lütfen internet bağlantınızı kontrol edin ve birkaç dakika sonra tekrar deneyin.
            </AlertDescription>
          </Alert>
        )}

        {overallStatus === 'success' && (
          <Alert>
            <CheckCircle className="h-4 w-4" />
            <AlertDescription>
              Tüm testler başarılı! Bağlantı sorunları çözülmüş görünüyor. 
              Şimdi hesap oluşturmayı tekrar deneyebilirsiniz.
            </AlertDescription>
          </Alert>
        )}
      </CardContent>
    </Card>
  );
}; 