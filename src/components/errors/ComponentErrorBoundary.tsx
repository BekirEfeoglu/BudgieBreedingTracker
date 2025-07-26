
import React, { Component, ErrorInfo, ReactNode } from 'react';
import { AlertTriangle, RefreshCw } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ComponentErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null
  };

  public static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('🔴 Component Error Boundary caught error:', error, errorInfo);
    
    // Call optional error handler
    if (this.props.onError) {
      this.props.onError(error, errorInfo);
    }
  }

  private handleRetry = () => {
    this.setState({
      hasError: false,
      error: null
    });
  };

  public render() {
    if (this.state.hasError) {
      // Use custom fallback if provided
      if (this.props.fallback) {
        return this.props.fallback;
      }

      // Default fallback UI
      return (
        <Card className="w-full border-red-200 bg-red-50">
          <CardContent className="p-6 text-center">
            <AlertTriangle className="w-12 h-12 text-red-500 mx-auto mb-3" />
            <h3 className="text-lg font-medium text-red-800 mb-2">
              Bileşen Yüklenemedi
            </h3>
            <p className="text-sm text-red-600 mb-4">
              Bu bölüm şu anda kullanılamıyor. Lütfen tekrar deneyin.
            </p>
            <Button 
              onClick={this.handleRetry}
              variant="outline"
              size="sm"
              className="text-red-700 border-red-300 hover:bg-red-100"
            >
              <RefreshCw className="w-4 h-4 mr-2" />
              Tekrar Dene
            </Button>
          </CardContent>
        </Card>
      );
    }

    return this.props.children;
  }
}

export default ComponentErrorBoundary;
