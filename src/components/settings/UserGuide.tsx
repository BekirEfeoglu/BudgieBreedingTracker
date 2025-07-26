import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { Separator } from '@/components/ui/separator';
import { 
  ArrowLeft, 
  Bird, 
  Egg, 
  Baby, 
  TreePine, 
  Calendar, 
  BarChart3, 
  Bell, 
  Settings, 
  Download, 
  Upload, 
  HelpCircle, 
  Play,
  BookOpen,
  Smartphone,
  Monitor,
  CheckCircle,
  AlertCircle,
  Info,
  ExternalLink,
  Mail,
  MessageSquare
} from 'lucide-react';

interface UserGuideProps {
  onBack?: () => void;
}

const UserGuide: React.FC<UserGuideProps> = ({ onBack }) => {
  const [activeTab, setActiveTab] = useState('getting-started');

  const quickStartSteps = [
    {
      step: 1,
      title: 'Hesap Oluşturun',
      description: 'E-posta adresinizle ücretsiz hesap oluşturun',
      icon: <CheckCircle className="h-5 w-5 text-green-600" />
    },
    {
      step: 2,
      title: 'İlk Kuşunuzu Ekleyin',
      description: 'Kuşlar sekmesinden "Kuş Ekle" butonuna tıklayın',
      icon: <Bird className="h-5 w-5 text-blue-600" />
    },
    {
      step: 3,
      title: 'Kuluçka Kaydı Başlatın',
      description: 'Kuş detayından üreme sürecini başlatın',
      icon: <Egg className="h-5 w-5 text-orange-600" />
    },
    {
      step: 4,
      title: 'Bildirimleri Aktif Edin',
      description: 'Önemli tarihleri kaçırmamak için bildirimleri açın',
      icon: <Bell className="h-5 w-5 text-purple-600" />
    }
  ];

  const features = [
    {
      icon: <Bird className="h-6 w-6" />,
      title: 'Kuş Yönetimi',
      description: 'Tüm kuşlarınızı detaylı bilgilerle tek yerden yönetin',
      details: [
        'Kuş ekleme ve düzenleme',
        'Fotoğraf yükleme',
        'Halka numarası takibi',
        'Sağlık notları',
        'Cinsiyet ve yaş bilgileri'
      ]
    },
    {
      icon: <Egg className="h-6 w-6" />,
      title: 'Kuluçka Takibi',
      description: 'Yumurta ve kuluçka süreçlerini adım adım takip edin',
      details: [
        'Yumurta sayısı kaydı',
        'Çıkış tarihi hesaplama',
        'Gelişim aşamaları',
        'Başarı oranı takibi',
        'Otomatik bildirimler'
      ]
    },
    {
      icon: <Baby className="h-6 w-6" />,
      title: 'Yavru Takibi',
      description: 'Yavru kuşların büyüme süreçlerini izleyin',
      details: [
        'Doğum tarihi kaydı',
        'Büyüme aşamaları',
        'Sağlık kontrolleri',
        'Cinsiyet belirleme',
        'Satış/verme kayıtları'
      ]
    },
    {
      icon: <TreePine className="h-6 w-6" />,
      title: 'Soy Ağacı',
      description: 'Kuşlarınızın aile geçmişini ve genetik bilgilerini takip edin',
      details: [
        'Otomatik soyağacı oluşturma',
        'Genetik özellik takibi',
        'Üreme geçmişi',
        'Aile bağlantıları',
        'Görsel ağaç gösterimi'
      ]
    },
    {
      icon: <Calendar className="h-6 w-6" />,
      title: 'Takvim',
      description: 'Önemli tarihleri ve olayları organize edin',
      details: [
        'Kuluçka tarihleri',
        'Çıkış tarihleri',
        'Sağlık kontrolleri',
        'Üreme planları',
        'Özel notlar'
      ]
    },
    {
      icon: <BarChart3 className="h-6 w-6" />,
      title: 'İstatistikler',
      description: 'Detaylı raporlar ve analizlerle üretiminizi optimize edin',
      details: [
        'Başarı oranları',
        'Üretim grafikleri',
        'Finansal takip',
        'Performans analizi',
        'PDF rapor alma'
      ]
    }
  ];

  const faqItems = [
    {
      question: 'Uygulama ücretsiz mi?',
      answer: 'Evet, temel özellikler tamamen ücretsizdir. Premium özellikler için ücretli planlar mevcuttur.'
    },
    {
      question: 'Verilerim güvende mi?',
      answer: 'Tüm verileriniz şifrelenmiş olarak saklanır ve sadece siz erişebilirsiniz. Düzenli yedekleme yapılır.'
    },
    {
      question: 'Mobil uygulama var mı?',
      answer: 'Evet, iOS ve Android için mobil uygulamalar mevcuttur. Web sitesinden de mobil cihazlarda kullanabilirsiniz.'
    },
    {
      question: 'Verilerimi dışa aktarabilir miyim?',
      answer: 'Evet, tüm verilerinizi Excel, CSV veya PDF formatında dışa aktarabilirsiniz.'
    },
    {
      question: 'Kaç kuş kaydedebilirim?',
      answer: 'Ücretsiz planda 50 kuş, premium planda sınırsız kuş kaydedebilirsiniz.'
    },
    {
      question: 'Bildirimler nasıl çalışır?',
      answer: 'Önemli tarihler yaklaştığında e-posta ve tarayıcı bildirimleri alırsınız. Ayarlardan özelleştirebilirsiniz.'
    },
    {
      question: 'Soyağacı otomatik oluşuyor mu?',
      answer: 'Evet, anne-baba bilgilerini girdiğinizde soyağacı otomatik olarak oluşturulur.'
    },
    {
      question: 'Yedekleme nasıl yapılır?',
      answer: 'Ayarlar sekmesinden otomatik veya manuel yedekleme yapabilirsiniz. Yedekler bulutta güvenle saklanır.'
    },
    {
      question: 'Teknik destek alabilir miyim?',
      answer: 'Evet, e-posta, telefon ve canlı destek kanallarından yardım alabilirsiniz.'
    },
    {
      question: 'Uygulama çevrimdışı çalışır mı?',
      answer: 'Temel özellikler çevrimdışı çalışır. İnternet bağlantısı gerektiren özellikler için uyarı alırsınız.'
    }
  ];

  const troubleshootingItems = [
    {
      problem: 'Uygulama açılmıyor',
      solutions: [
        'Tarayıcı önbelleğini temizleyin (Ctrl+F5)',
        'Farklı bir tarayıcı deneyin',
        'İnternet bağlantınızı kontrol edin',
        'Tarayıcı güncellemelerini kontrol edin'
      ]
    },
    {
      problem: 'Verilerim kayboldu',
      solutions: [
        'Yedekleme sekmesinden verilerinizi geri yükleyin',
        'Farklı bir cihazda giriş yapmayı deneyin',
        'Destek ekibiyle iletişime geçin'
      ]
    },
    {
      problem: 'Bildirimler gelmiyor',
      solutions: [
        'Tarayıcı bildirim izinlerini kontrol edin',
        'Ayarlardan bildirim tercihlerini gözden geçirin',
        'E-posta spam klasörünü kontrol edin'
      ]
    },
    {
      problem: 'Fotoğraf yüklenmiyor',
      solutions: [
        'Dosya boyutunu kontrol edin (max 5MB)',
        'Desteklenen formatları kullanın (JPG, PNG)',
        'İnternet bağlantınızı kontrol edin'
      ]
    },
    {
      problem: 'Sayfa yavaş yükleniyor',
      solutions: [
        'Tarayıcı önbelleğini temizleyin',
        'Diğer sekmeleri kapatın',
        'İnternet bağlantınızı kontrol edin'
      ]
    }
  ];

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        {onBack && (
          <Button variant="ghost" size="icon" onClick={onBack}>
            <ArrowLeft className="w-5 h-5" />
          </Button>
        )}
        <div>
          <h1 className="text-3xl font-bold">Kullanım Kılavuzu</h1>
          <p className="text-muted-foreground">BudgieBreedingTracker uygulamasının detaylı kullanım rehberi</p>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="getting-started">Başlangıç</TabsTrigger>
          <TabsTrigger value="features">Özellikler</TabsTrigger>
          <TabsTrigger value="tutorials">Video Rehberler</TabsTrigger>
          <TabsTrigger value="faq">SSS</TabsTrigger>
          <TabsTrigger value="troubleshooting">Sorun Giderme</TabsTrigger>
        </TabsList>

        {/* Başlangıç */}
        <TabsContent value="getting-started" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Play className="h-5 w-5" />
                Hızlı Başlangıç
              </CardTitle>
              <CardDescription>
                Uygulamayı kullanmaya başlamak için bu adımları takip edin
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-6">
                {quickStartSteps.map((step, index) => (
                  <div key={index} className="flex items-start gap-4 p-4 border rounded-lg">
                    <div className="flex-shrink-0 w-8 h-8 bg-primary text-primary-foreground rounded-full flex items-center justify-center font-bold">
                      {step.step}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        {step.icon}
                        <h3 className="font-semibold">{step.title}</h3>
                      </div>
                      <p className="text-muted-foreground">{step.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Smartphone className="h-5 w-5" />
                Platform Desteği
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="text-center p-4 border rounded-lg">
                  <Monitor className="h-12 w-12 mx-auto mb-2 text-blue-600" />
                  <h3 className="font-semibold">Web Uygulaması</h3>
                  <p className="text-sm text-muted-foreground">Tüm modern tarayıcılarda çalışır</p>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <Smartphone className="h-12 w-12 mx-auto mb-2 text-green-600" />
                  <h3 className="font-semibold">Mobil Uygulama</h3>
                  <p className="text-sm text-muted-foreground">iOS ve Android için</p>
                </div>
                <div className="text-center p-4 border rounded-lg">
                  <Settings className="h-12 w-12 mx-auto mb-2 text-purple-600" />
                  <h3 className="font-semibold">Çevrimdışı Çalışma</h3>
                  <p className="text-sm text-muted-foreground">İnternet olmadan da kullanın</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Özellikler */}
        <TabsContent value="features" className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {features.map((feature, index) => (
              <Card key={index}>
                <CardHeader>
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-primary/10 rounded-lg">
                      {feature.icon}
                    </div>
                    <div>
                      <CardTitle className="text-lg">{feature.title}</CardTitle>
                      <CardDescription>{feature.description}</CardDescription>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-2">
                    {feature.details.map((detail, detailIndex) => (
                      <li key={detailIndex} className="flex items-center gap-2 text-sm">
                        <CheckCircle className="h-4 w-4 text-green-600 flex-shrink-0" />
                        {detail}
                      </li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Video Rehberler */}
        <TabsContent value="tutorials" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Play className="h-5 w-5" />
                Video Rehberler
              </CardTitle>
              <CardDescription>
                Uygulamanın nasıl kullanılacağını öğrenmek için bu videoları izleyin
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4">
                <div className="p-4 border rounded-lg">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-16 h-12 bg-gray-200 rounded flex items-center justify-center">
                      <Play className="h-6 w-6" />
                    </div>
                    <div>
                      <h3 className="font-semibold">Uygulamaya Giriş ve İlk Kurulum</h3>
                      <p className="text-sm text-muted-foreground">Süre: 5 dakika</p>
                    </div>
                  </div>
                  <p className="text-sm text-muted-foreground mb-3">
                    Hesap oluşturma, profil ayarları ve ilk kuş ekleme işlemleri
                  </p>
                  <Button variant="outline" size="sm">
                    <ExternalLink className="h-3 w-3 mr-1" />
                    İzle
                  </Button>
                </div>

                <div className="p-4 border rounded-lg">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-16 h-12 bg-gray-200 rounded flex items-center justify-center">
                      <Play className="h-6 w-6" />
                    </div>
                    <div>
                      <h3 className="font-semibold">Kuluçka Takibi Nasıl Yapılır</h3>
                      <p className="text-sm text-muted-foreground">Süre: 8 dakika</p>
                    </div>
                  </div>
                  <p className="text-sm text-muted-foreground mb-3">
                    Yumurta kaydı, çıkış tarihi hesaplama ve yavru takibi
                  </p>
                  <Button variant="outline" size="sm">
                    <ExternalLink className="h-3 w-3 mr-1" />
                    İzle
                  </Button>
                </div>

                <div className="p-4 border rounded-lg">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-16 h-12 bg-gray-200 rounded flex items-center justify-center">
                      <Play className="h-6 w-6" />
                    </div>
                    <div>
                      <h3 className="font-semibold">Soy Ağacı ve İstatistikler</h3>
                      <p className="text-sm text-muted-foreground">Süre: 6 dakika</p>
                    </div>
                  </div>
                  <p className="text-sm text-muted-foreground mb-3">
                    Soyağacı oluşturma, istatistik analizi ve rapor alma
                  </p>
                  <Button variant="outline" size="sm">
                    <ExternalLink className="h-3 w-3 mr-1" />
                    İzle
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* SSS */}
        <TabsContent value="faq" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <HelpCircle className="h-5 w-5" />
                Sık Sorulan Sorular
              </CardTitle>
              <CardDescription>
                En çok sorulan sorular ve cevapları
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Accordion type="single" collapsible className="w-full">
                {faqItems.map((item, index) => (
                  <AccordionItem key={index} value={`item-${index}`}>
                    <AccordionTrigger className="text-left">
                      {item.question}
                    </AccordionTrigger>
                    <AccordionContent>
                      <p className="text-muted-foreground">{item.answer}</p>
                    </AccordionContent>
                  </AccordionItem>
                ))}
              </Accordion>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Sorun Giderme */}
        <TabsContent value="troubleshooting" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertCircle className="h-5 w-5" />
                Sorun Giderme
              </CardTitle>
              <CardDescription>
                Yaygın sorunlar ve çözümleri
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Accordion type="single" collapsible className="w-full">
                {troubleshootingItems.map((item, index) => (
                  <AccordionItem key={index} value={`trouble-${index}`}>
                    <AccordionTrigger className="text-left">
                      <div className="flex items-center gap-2">
                        <AlertCircle className="h-4 w-4 text-orange-600" />
                        {item.problem}
                      </div>
                    </AccordionTrigger>
                    <AccordionContent>
                      <div className="space-y-2">
                        {item.solutions.map((solution, solutionIndex) => (
                          <div key={solutionIndex} className="flex items-start gap-2">
                            <CheckCircle className="h-4 w-4 text-green-600 mt-0.5 flex-shrink-0" />
                            <span className="text-sm">{solution}</span>
                          </div>
                        ))}
                      </div>
                    </AccordionContent>
                  </AccordionItem>
                ))}
              </Accordion>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Info className="h-5 w-5" />
                İletişim ve Destek
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 border rounded-lg">
                  <h3 className="font-semibold mb-2">E-posta Desteği</h3>
                  <p className="text-sm text-muted-foreground mb-2">
                    Teknik sorunlar için e-posta gönderin
                  </p>
                  <Button variant="outline" size="sm">
                    <Mail className="h-3 w-3 mr-1" />
                    admin@budgiebreedingtracker.com
                  </Button>
                </div>
                <div className="p-4 border rounded-lg">
                  <h3 className="font-semibold mb-2">Canlı Destek</h3>
                  <p className="text-sm text-muted-foreground mb-2">
                    Anlık yardım için canlı destek
                  </p>
                  <Button variant="outline" size="sm">
                    <MessageSquare className="h-3 w-3 mr-1" />
                    Canlı Destek
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default UserGuide;