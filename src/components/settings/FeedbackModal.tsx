import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/useAuth';
import { X, Send, Star, Bug, Lightbulb, MessageSquare, CheckCircle } from 'lucide-react';
import { useLanguage } from '@/contexts/LanguageContext';
import FeedbackService from '@/services/feedback/FeedbackService';

interface FeedbackModalProps {
  isOpen: boolean;
  onClose: () => void;
}

type FeedbackType = 'bug' | 'feature' | 'improvement' | 'general';
type PriorityLevel = 'low' | 'medium' | 'high' | 'critical';

interface FeedbackData {
  type: FeedbackType;
  priority: PriorityLevel;
  title: string;
  description: string;
  userEmail?: string;
  includeSystemInfo: boolean;
  includeScreenshot: boolean;
  rating?: number | undefined;
}

const defaultFeedbackData: FeedbackData = {
  type: 'general',
  priority: 'medium',
  title: '',
  description: '',
  userEmail: '',
  includeSystemInfo: true,
  includeScreenshot: false,
  rating: undefined
};

export const FeedbackModal: React.FC<FeedbackModalProps> = ({ isOpen, onClose }) => {
  const [feedback, setFeedback] = useState<FeedbackData>(defaultFeedbackData);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [currentStep, setCurrentStep] = useState(1);
  const { toast } = useToast();
  const { user } = useAuth();
  const { t } = useLanguage();

  const feedbackTypes = [
    { value: 'bug', label: 'Hata Bildirimi', icon: Bug, color: 'text-red-500' },
    { value: 'feature', label: 'Yeni Özellik Önerisi', icon: Lightbulb, color: 'text-blue-500' },
    { value: 'improvement', label: 'İyileştirme Önerisi', icon: Star, color: 'text-yellow-500' },
    { value: 'general', label: 'Genel Geri Bildirim', icon: MessageSquare, color: 'text-green-500' }
  ];

  const priorityLevels = [
    { value: 'low', label: 'Düşük', color: 'bg-green-100 text-green-800' },
    { value: 'medium', label: 'Orta', color: 'bg-yellow-100 text-yellow-800' },
    { value: 'high', label: 'Yüksek', color: 'bg-orange-100 text-orange-800' },
    { value: 'critical', label: 'Kritik', color: 'bg-red-100 text-red-800' }
  ];

  const getSystemInfo = () => {
    return {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      language: navigator.language,
      screenResolution: `${screen.width}x${screen.height}`,
      windowSize: `${window.innerWidth}x${window.innerHeight}`,
      timestamp: new Date().toISOString(),
      userId: user?.id,
      userEmail: user?.email
    };
  };

  const handleSubmit = async () => {
    if (!feedback.title.trim() || !feedback.description.trim()) {
      toast({
        title: 'Eksik Bilgi',
        description: 'Lütfen başlık ve açıklama alanlarını doldurun.',
        variant: 'destructive'
      });
      return;
    }

    setIsSubmitting(true);

    try {
      const feedbackData = {
        ...feedback,
        userEmail: feedback.userEmail || user?.email || undefined
      };

      // Geri bildirim servisi ile gönder
      const feedbackService = FeedbackService.getInstance();
      const result = await feedbackService.submitFeedback(feedbackData);

      if (!result.success) {
        throw new Error(result.error || 'Geri bildirim gönderilemedi');
      }

      toast({
        title: 'Geri Bildirim Gönderildi',
        description: feedbackData.userEmail || user?.email 
          ? 'Geri bildiriminiz alındı ve onay e-postası gönderildi. En kısa sürede değerlendireceğiz.'
          : 'Değerli geri bildiriminiz için teşekkürler! En kısa sürede değerlendireceğiz.',
      });

      // Formu sıfırla
      setFeedback(defaultFeedbackData);
      setCurrentStep(1);
      onClose();

    } catch (error) {
      console.error('Geri bildirim gönderme hatası:', error);
      toast({
        title: 'Hata',
        description: 'Geri bildirim gönderilirken bir hata oluştu. Lütfen tekrar deneyin.',
        variant: 'destructive'
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (isSubmitting) return;
    setFeedback(defaultFeedbackData);
    setCurrentStep(1);
    onClose();
  };

  const updateFeedback = (field: keyof FeedbackData, value: any) => {
    setFeedback(prev => ({ ...prev, [field]: value }));
  };

  const renderStep1 = () => (
    <div className="space-y-6">
      <div>
        <Label className="text-base font-medium">Geri Bildirim Türü</Label>
        <p className="text-sm text-muted-foreground mb-4">
          Hangi türde geri bildirim göndermek istiyorsunuz?
        </p>
        <RadioGroup
          value={feedback.type}
          onValueChange={(value: FeedbackType) => updateFeedback('type', value)}
          className="grid grid-cols-2 gap-3"
        >
          {feedbackTypes.map((type) => {
            const Icon = type.icon;
            return (
              <div key={type.value} className="flex items-center space-x-2">
                <RadioGroupItem value={type.value} id={type.value} />
                <Label htmlFor={type.value} className="flex items-center gap-2 cursor-pointer">
                  <Icon className={`w-4 h-4 ${type.color}`} />
                  {type.label}
                </Label>
              </div>
            );
          })}
        </RadioGroup>
      </div>

      <div>
        <Label className="text-base font-medium">Öncelik Seviyesi</Label>
        <p className="text-sm text-muted-foreground mb-4">
          Bu geri bildirimin öncelik seviyesini belirleyin
        </p>
        <Select
          value={feedback.priority}
          onValueChange={(value: PriorityLevel) => updateFeedback('priority', value)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {priorityLevels.map((level) => (
              <SelectItem key={level.value} value={level.value}>
                <Badge className={level.color}>{level.label}</Badge>
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex gap-2 pt-4">
        <Button variant="outline" onClick={handleClose} className="flex-1">
          İptal
        </Button>
        <Button onClick={() => setCurrentStep(2)} className="flex-1">
          Devam Et
        </Button>
      </div>
    </div>
  );

  const renderStep2 = () => (
    <div className="space-y-6">
      <div>
        <Label htmlFor="feedback-title" className="text-base font-medium">
          Başlık *
        </Label>
        <Input
          id="feedback-title"
          placeholder="Geri bildiriminizi kısaca özetleyin"
          value={feedback.title}
          onChange={(e) => updateFeedback('title', e.target.value)}
          maxLength={100}
        />
        <p className="text-xs text-muted-foreground mt-1">
          {feedback.title.length}/100 karakter
        </p>
      </div>

      <div>
        <Label htmlFor="feedback-description" className="text-base font-medium">
          Detaylı Açıklama *
        </Label>
        <Textarea
          id="feedback-description"
          placeholder="Geri bildiriminizi detaylı olarak açıklayın..."
          value={feedback.description}
          onChange={(e) => updateFeedback('description', e.target.value)}
          rows={6}
          maxLength={1000}
        />
        <p className="text-xs text-muted-foreground mt-1">
          {feedback.description.length}/1000 karakter
        </p>
      </div>

      {feedback.type === 'bug' && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <h4 className="font-medium text-red-800 mb-2">Hata Bildirimi İçin Öneriler:</h4>
          <ul className="text-sm text-red-700 space-y-1">
            <li>• Hatayı nasıl tekrarlayabileceğimizi açıklayın</li>
            <li>• Hata oluştuğunda ne yapıyordunuz?</li>
            <li>• Beklenen davranış ne olmalıydı?</li>
            <li>• Ekran görüntüsü eklemek yardımcı olabilir</li>
          </ul>
        </div>
      )}

      {feedback.type === 'feature' && (
        <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <h4 className="font-medium text-blue-800 mb-2">Özellik Önerisi İçin Öneriler:</h4>
          <ul className="text-sm text-blue-700 space-y-1">
            <li>• Bu özellik size nasıl yardımcı olacak?</li>
            <li>• Benzer özellikler var mı?</li>
            <li>• Öncelik sırası nedir?</li>
            <li>• Kullanım senaryolarını açıklayın</li>
          </ul>
        </div>
      )}

      <div className="flex gap-2 pt-4">
        <Button variant="outline" onClick={() => setCurrentStep(1)} className="flex-1">
          Geri
        </Button>
        <Button onClick={() => setCurrentStep(3)} className="flex-1">
          Devam Et
        </Button>
      </div>
    </div>
  );

  const renderStep3 = () => (
    <div className="space-y-6">
      <div>
        <Label htmlFor="user-email" className="text-base font-medium">
          İletişim E-postası
        </Label>
        <Input
          id="user-email"
          type="email"
          placeholder="Size geri dönmek için (opsiyonel)"
          value={feedback.userEmail}
          onChange={(e) => updateFeedback('userEmail', e.target.value)}
        />
        <p className="text-xs text-muted-foreground mt-1">
          Geri bildiriminizle ilgili size ulaşabilmek için
        </p>
      </div>

      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <Label className="text-base font-medium">Sistem Bilgilerini Dahil Et</Label>
            <p className="text-sm text-muted-foreground">
              Tarayıcı, işletim sistemi ve ekran bilgileri
            </p>
          </div>
          <input
            type="checkbox"
            checked={feedback.includeSystemInfo}
            onChange={(e) => updateFeedback('includeSystemInfo', e.target.checked)}
            className="w-4 h-4"
          />
        </div>

        <div className="flex items-center justify-between">
          <div>
            <Label className="text-base font-medium">Ekran Görüntüsü Ekle</Label>
            <p className="text-sm text-muted-foreground">
              Sorunu daha iyi anlamamıza yardımcı olur
            </p>
          </div>
          <input
            type="checkbox"
            checked={feedback.includeScreenshot}
            onChange={(e) => updateFeedback('includeScreenshot', e.target.checked)}
            className="w-4 h-4"
          />
        </div>
      </div>

      {feedback.includeScreenshot && (
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-sm text-yellow-800">
            <strong>Not:</strong> Ekran görüntüsü özelliği henüz geliştirme aşamasındadır. 
            Manuel olarak ekran görüntüsü alıp açıklamanıza ekleyebilirsiniz.
          </p>
        </div>
      )}

      <div className="flex gap-2 pt-4">
        <Button variant="outline" onClick={() => setCurrentStep(2)} className="flex-1">
          Geri
        </Button>
        <Button 
          onClick={handleSubmit} 
          disabled={isSubmitting || !feedback.title.trim() || !feedback.description.trim()}
          className="flex-1"
        >
          {isSubmitting ? (
            <>
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
              Gönderiliyor...
            </>
          ) : (
            <>
              <Send className="w-4 h-4 mr-2" />
              Geri Bildirim Gönder
            </>
          )}
        </Button>
      </div>
    </div>
  );

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <MessageSquare className="w-5 h-5" />
              Geri Bildirim Gönder
            </div>
            <Button variant="ghost" size="icon" onClick={handleClose} disabled={isSubmitting}>
              <X className="w-4 h-4" />
            </Button>
          </DialogTitle>
          <DialogDescription>
            Uygulamamızı geliştirmemize yardımcı olun. Geri bildiriminiz bizim için çok değerli.
          </DialogDescription>
        </DialogHeader>

        <div className="mt-4">
          {/* Progress Bar */}
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2">
              {[1, 2, 3].map((step) => (
                <div key={step} className="flex items-center">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                    step <= currentStep 
                      ? 'bg-primary text-primary-foreground' 
                      : 'bg-muted text-muted-foreground'
                  }`}>
                    {step < currentStep ? <CheckCircle className="w-4 h-4" /> : step}
                  </div>
                  {step < 3 && (
                    <div className={`w-12 h-1 mx-2 ${
                      step < currentStep ? 'bg-primary' : 'bg-muted'
                    }`} />
                  )}
                </div>
              ))}
            </div>
            <Badge variant="outline">Adım {currentStep}/3</Badge>
          </div>

          <Separator className="mb-6" />

          {/* Step Content */}
          {currentStep === 1 && renderStep1()}
          {currentStep === 2 && renderStep2()}
          {currentStep === 3 && renderStep3()}
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default FeedbackModal; 