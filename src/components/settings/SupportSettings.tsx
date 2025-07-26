import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/useAuth';
import FeedbackModal from './FeedbackModal';
import FeedbackService from '@/services/feedback/FeedbackService';
import { MessageSquare, HelpCircle, BookOpen, Mail, ExternalLink, Plus, Clock, CheckCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const SupportSettings = () => {
  const { toast } = useToast();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [isFeedbackModalOpen, setIsFeedbackModalOpen] = useState(false);
  const [feedbacks, setFeedbacks] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const feedbackService = FeedbackService.getInstance();

  useEffect(() => {
    if (user) {
      loadFeedbacks();
    }
  }, [user]);

  const loadFeedbacks = async () => {
    if (!user) return;

    setLoading(true);
    try {
      const result = await feedbackService.getFeedbackList(user.id);
      if (result.success && result.data) {
        setFeedbacks(result.data);
      }
    } catch (error) {
      console.error('Feedback listesi yüklenirken hata:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="outline" className="text-orange-600">Beklemede</Badge>;
      case 'reviewed':
        return <Badge variant="outline" className="text-blue-600">İncelendi</Badge>;
      case 'resolved':
        return <Badge variant="outline" className="text-green-600">Çözüldü</Badge>;
      case 'closed':
        return <Badge variant="outline" className="text-gray-600">Kapatıldı</Badge>;
      default:
        return <Badge variant="outline">Bilinmiyor</Badge>;
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'bug': return <MessageSquare className="h-4 w-4 text-red-500" />;
      case 'feature': return <MessageSquare className="h-4 w-4 text-blue-500" />;
      case 'improvement': return <MessageSquare className="h-4 w-4 text-yellow-500" />;
      default: return <MessageSquare className="h-4 w-4 text-green-500" />;
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('tr-TR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  return (
    <div className="space-y-6">
      {/* Destek Kanalları */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HelpCircle className="h-5 w-5" />
            Destek Kanalları
          </CardTitle>
          <CardDescription>
            Size yardımcı olabileceğimiz farklı yollar
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Button
              variant="outline"
              className="h-auto p-4 flex flex-col items-start gap-2"
              onClick={() => setIsFeedbackModalOpen(true)}
            >
              <MessageSquare className="h-5 w-5" />
              <div className="text-left">
                <div className="font-medium">Geri Bildirim Gönder</div>
                <div className="text-sm text-muted-foreground">
                  Hata bildirimi, özellik önerisi veya genel geri bildirim
                </div>
              </div>
            </Button>

            <Button
              variant="outline"
              className="h-auto p-4 flex flex-col items-start gap-2"
              onClick={() => window.open('mailto:admin@budgiebreedingtracker.com', '_blank')}
            >
              <Mail className="h-5 w-5" />
              <div className="text-left">
                <div className="font-medium">E-posta ile İletişim</div>
                <div className="text-sm text-muted-foreground">
                  Doğrudan e-posta ile destek alın
                </div>
              </div>
            </Button>

            <Button
              variant="outline"
              className="h-auto p-4 flex flex-col items-start gap-2"
              onClick={() => navigate('/user-guide')}
            >
              <BookOpen className="h-5 w-5" />
              <div className="text-left">
                <div className="font-medium">Kullanım Kılavuzu</div>
                <div className="text-sm text-muted-foreground">
                  Detaylı kullanım talimatları ve SSS
                </div>
              </div>
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Geri Bildirim Geçmişi */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="h-5 w-5" />
            Geri Bildirim Geçmişi
          </CardTitle>
          <CardDescription>
            Daha önce gönderdiğiniz geri bildirimler
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[...Array(3)].map((_, i) => (
                <div key={i} className="h-16 bg-muted rounded animate-pulse"></div>
              ))}
            </div>
          ) : feedbacks.length > 0 ? (
            <div className="space-y-3">
              {feedbacks.map((feedback) => (
                <div key={feedback.id} className="p-4 border rounded-lg">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3">
                      {getTypeIcon(feedback.type)}
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <h4 className="font-medium">{feedback.title}</h4>
                          {getStatusBadge(feedback.status)}
                        </div>
                        <p className="text-sm text-muted-foreground mb-2">
                          {feedback.description}
                        </p>
                        <div className="flex items-center gap-4 text-xs text-muted-foreground">
                          <span>{formatDate(feedback.createdAt)}</span>
                          {feedback.rating > 0 && (
                            <span>Değerlendirme: {feedback.rating}/5</span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <MessageSquare className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">Henüz geri bildirim göndermediniz</p>
              <Button
                onClick={() => setIsFeedbackModalOpen(true)}
                className="mt-4"
              >
                <Plus className="h-4 w-4 mr-2" />
                İlk Geri Bildiriminizi Gönderin
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Hızlı Yardım */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HelpCircle className="h-5 w-5" />
            Hızlı Yardım
          </CardTitle>
          <CardDescription>
            Sık sorulan sorular ve hızlı çözümler
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-3">
            <div className="p-4 border rounded-lg">
              <h4 className="font-medium mb-2">Uygulama açılmıyor</h4>
              <p className="text-sm text-muted-foreground mb-3">
                Tarayıcı önbelleğini temizleyin ve sayfayı yenileyin.
              </p>
              <Button variant="outline" size="sm">
                <ExternalLink className="h-3 w-3 mr-1" />
                Detaylı Çözüm
              </Button>
            </div>

            <div className="p-4 border rounded-lg">
              <h4 className="font-medium mb-2">Verilerim kayboldu</h4>
              <p className="text-sm text-muted-foreground mb-3">
                Yedekleme sekmesinden verilerinizi geri yükleyebilirsiniz.
              </p>
              <Button variant="outline" size="sm">
                <ExternalLink className="h-3 w-3 mr-1" />
                Yedekleme Rehberi
              </Button>
            </div>

            <div className="p-4 border rounded-lg">
              <h4 className="font-medium mb-2">Bildirimler gelmiyor</h4>
              <p className="text-sm text-muted-foreground mb-3">
                Tarayıcı izinlerini kontrol edin ve bildirim ayarlarını gözden geçirin.
              </p>
              <Button variant="outline" size="sm">
                <ExternalLink className="h-3 w-3 mr-1" />
                Bildirim Ayarları
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Feedback Modal */}
      <FeedbackModal
        isOpen={isFeedbackModalOpen}
        onClose={() => {
          setIsFeedbackModalOpen(false);
          loadFeedbacks(); // Refresh feedback list
        }}
      />
    </div>
  );
};

export default SupportSettings;
