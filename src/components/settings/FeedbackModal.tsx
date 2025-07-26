import React, { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/useAuth';
import { X, Send, Star, Bug, Lightbulb, MessageSquare, CheckCircle } from 'lucide-react';
import FeedbackService from '@/services/feedback/FeedbackService';

const defaultFeedbackData = {
  type: 'general',
  title: '',
  description: '',
  rating: 0,
};

interface FeedbackModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const FeedbackModal = ({ isOpen, onClose }: FeedbackModalProps) => {
  const { toast } = useToast();
  const { user } = useAuth();
  const [feedbackData, setFeedbackData] = useState(defaultFeedbackData);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const feedbackService = FeedbackService.getInstance();

  const handleSubmit = async () => {
    if (!user) {
      toast({
        title: 'Hata',
        description: 'Kullanıcı girişi gerekli',
        variant: 'destructive',
      });
      return;
    }

    if (!feedbackData.title.trim() || !feedbackData.description.trim()) {
      toast({
        title: 'Eksik Bilgi',
        description: 'Lütfen başlık ve açıklama alanlarını doldurun',
        variant: 'destructive',
      });
      return;
    }

    setIsSubmitting(true);
    try {
      const result = await feedbackService.submitFeedback({
        userId: user.id,
        type: feedbackData.type as any,
        title: feedbackData.title,
        description: feedbackData.description,
        rating: feedbackData.rating,
      });

      if (result.success) {
        toast({
          title: 'Başarılı',
          description: 'Geri bildiriminiz başarıyla gönderildi',
        });
        handleClose();
      } else {
        throw new Error(result.error);
      }
    } catch (error) {
      console.error('Feedback gönderme hatası:', error);
      toast({
        title: 'Hata',
        description: 'Geri bildirim gönderilemedi',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    setFeedbackData(defaultFeedbackData);
    onClose();
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'bug': return <Bug className="h-4 w-4" />;
      case 'feature': return <Lightbulb className="h-4 w-4" />;
      case 'improvement': return <Star className="h-4 w-4" />;
      default: return <MessageSquare className="h-4 w-4" />;
    }
  };

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'bug': return 'Hata Bildirimi';
      case 'feature': return 'Özellik Önerisi';
      case 'improvement': return 'İyileştirme';
      default: return 'Genel';
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <MessageSquare className="h-5 w-5" />
            Geri Bildirim Gönder
          </DialogTitle>
          <DialogDescription>
            Deneyiminizi paylaşın, önerilerinizi belirtin veya hata bildirin
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Feedback Type */}
          <div className="space-y-2">
            <Label>Geri Bildirim Türü</Label>
            <Select
              value={feedbackData.type}
              onValueChange={(value) => setFeedbackData(prev => ({ ...prev, type: value }))}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="general">
                  <div className="flex items-center gap-2">
                    <MessageSquare className="h-4 w-4" />
                    Genel
                  </div>
                </SelectItem>
                <SelectItem value="bug">
                  <div className="flex items-center gap-2">
                    <Bug className="h-4 w-4" />
                    Hata Bildirimi
                  </div>
                </SelectItem>
                <SelectItem value="feature">
                  <div className="flex items-center gap-2">
                    <Lightbulb className="h-4 w-4" />
                    Özellik Önerisi
                  </div>
                </SelectItem>
                <SelectItem value="improvement">
                  <div className="flex items-center gap-2">
                    <Star className="h-4 w-4" />
                    İyileştirme
                  </div>
                </SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Title */}
          <div className="space-y-2">
            <Label>Başlık</Label>
            <Input
              placeholder="Kısa bir başlık girin"
              value={feedbackData.title}
              onChange={(e) => setFeedbackData(prev => ({ ...prev, title: e.target.value }))}
            />
          </div>

          {/* Description */}
          <div className="space-y-2">
            <Label>Açıklama</Label>
            <Textarea
              placeholder="Detaylı açıklama yazın..."
              value={feedbackData.description}
              onChange={(e) => setFeedbackData(prev => ({ ...prev, description: e.target.value }))}
              rows={4}
            />
          </div>

          {/* Rating */}
          <div className="space-y-2">
            <Label>Değerlendirme</Label>
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map((star) => (
                <button
                  key={star}
                  type="button"
                  onClick={() => setFeedbackData(prev => ({ ...prev, rating: star }))}
                  className={`p-1 rounded transition-colors ${
                    feedbackData.rating >= star ? 'text-yellow-500' : 'text-gray-300'
                  }`}
                >
                  <Star className="h-5 w-5 fill-current" />
                </button>
              ))}
            </div>
            <p className="text-sm text-muted-foreground">
              {feedbackData.rating === 0 && 'Değerlendirme yapmadınız'}
              {feedbackData.rating === 1 && 'Çok kötü'}
              {feedbackData.rating === 2 && 'Kötü'}
              {feedbackData.rating === 3 && 'Orta'}
              {feedbackData.rating === 4 && 'İyi'}
              {feedbackData.rating === 5 && 'Mükemmel'}
            </p>
          </div>

          {/* Preview */}
          {feedbackData.title && (
            <div className="p-3 border rounded-lg bg-muted/50">
              <div className="flex items-center gap-2 mb-2">
                {getTypeIcon(feedbackData.type)}
                <Badge variant="outline">{getTypeLabel(feedbackData.type)}</Badge>
              </div>
              <h4 className="font-medium">{feedbackData.title}</h4>
              <p className="text-sm text-muted-foreground mt-1">{feedbackData.description}</p>
            </div>
          )}
        </div>

        <div className="flex gap-2 justify-end">
          <Button variant="outline" onClick={handleClose}>
            İptal
          </Button>
          <Button
            onClick={handleSubmit}
            disabled={isSubmitting || !feedbackData.title.trim() || !feedbackData.description.trim()}
          >
            {isSubmitting ? (
              <>
                <CheckCircle className="h-4 w-4 mr-2 animate-spin" />
                Gönderiliyor...
              </>
            ) : (
              <>
                <Send className="h-4 w-4 mr-2" />
                Gönder
              </>
            )}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default FeedbackModal; 