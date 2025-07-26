
import React, { Component, ErrorInfo, ReactNode } from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

class GlobalErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null,
    errorInfo: null
  };

  public static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('🚨 Global Error Boundary caught error:', error, errorInfo);
    
    // Log error details for debugging
    console.error('Error stack:', error.stack);
    console.error('Component stack:', errorInfo.componentStack);
    
    this.setState({
      error,
      errorInfo
    });

    // Report to external error tracking service if available
    // Example: Sentry.captureException(error, { contexts: { react: errorInfo } });
  }

  private handleReload = () => {
    window.location.reload();
  };

  private handleGoHome = () => {
    window.location.href = '/';
  };

  private handleReset = () => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null
    });
  };

  public render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-gradient-to-br from-red-50 via-orange-50 to-yellow-50 flex items-center justify-center p-4">
          <Card className="w-full max-w-2xl shadow-xl">
            <CardHeader className="text-center">
              <div className="mx-auto mb-4 w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
                <AlertTriangle className="w-8 h-8 text-red-600" />
              </div>
              <CardTitle className="text-2xl font-bold text-red-800">
                Oops! Bir Hata Oluştu
              </CardTitle>
              <CardDescription className="text-gray-600 mt-2">
                Uygulama beklenmeyen bir hatayla karşılaştı. Bu durumu düzeltmek için aşağıdaki seçenekleri deneyebilirsiniz.
              </CardDescription>
            </CardHeader>
            
            <CardContent className="space-y-6">
              {/* Error Actions */}
              <div className="flex flex-col sm:flex-row gap-3 justify-center">
                <Button 
                  onClick={this.handleReset}
                  variant="default"
                  className="flex items-center gap-2"
                >
                  <RefreshCw className="w-4 h-4" />
                  Tekrar Dene
                </Button>
                
                <Button 
                  onClick={this.handleReload}
                  variant="outline"
                  className="flex items-center gap-2"
                >
                  <RefreshCw className="w-4 h-4" />
                  Sayfayı Yenile
                </Button>
                
                <Button 
                  onClick={this.handleGoHome}
                  variant="outline"
                  className="flex items-center gap-2"
                >
                  <Home className="w-4 h-4" />
                  Ana Sayfa
                </Button>
              </div>

              {/* Error Details (Development Only) */}
              {process.env.NODE_ENV === 'development' && this.state.error && (
                <details className="mt-6 p-4 bg-gray-50 rounded-lg border">
                  <summary className="cursor-pointer font-medium text-sm text-gray-700 mb-2">
                    Hata Detayları (Geliştirici Modu)
                  </summary>
                  <div className="space-y-3 text-xs">
                    <div>
                      <strong className="text-red-600">Hata Mesajı:</strong>
                      <pre className="mt-1 p-2 bg-red-50 border border-red-200 rounded text-red-800 overflow-x-auto">
                        {this.state.error.message}
                      </pre>
                    </div>
                    
                    {this.state.error.stack && (
                      <div>
                        <strong className="text-red-600">Stack Trace:</strong>
                        <pre className="mt-1 p-2 bg-red-50 border border-red-200 rounded text-red-800 overflow-x-auto max-h-32">
                          {this.state.error.stack}
                        </pre>
                      </div>
                    )}
                    
                    {this.state.errorInfo?.componentStack && (
                      <div>
                        <strong className="text-red-600">Component Stack:</strong>
                        <pre className="mt-1 p-2 bg-red-50 border border-red-200 rounded text-red-800 overflow-x-auto max-h-32">
                          {this.state.errorInfo.componentStack}
                        </pre>
                      </div>
                    )}
                  </div>
                </details>
              )}

              {/* Help Text */}
              <div className="text-center text-sm text-gray-500 border-t pt-4">
                <p>
                  Sorun devam ederse, lütfen tarayıcınızın önbelleğini temizleyin 
                  veya uygulama içi geri bildirim formunu kullanın.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      );
    }

    return this.props.children;
  }
}

export default GlobalErrorBoundary;
