import React, { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Plus } from 'lucide-react';
import { usePushNotifications } from '@/hooks/usePushNotifications';
import { format } from 'date-fns';
import { useLanguage } from '@/contexts/LanguageContext';
import { formatDateForInput, formatTimeForInput } from '@/utils/dateUtils';
import { useFormValidation } from '@/hooks/useFormValidation';
import { toast } from '@/hooks/use-toast';

interface CreateNotificationModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export const CreateNotificationModal: React.FC<CreateNotificationModalProps> = ({
  open,
  onOpenChange
}) => {
  const {
    createIncubationReminder,
    createFeedingReminder,
    createVeterinaryReminder,
    createBreedingReminder,
    createEventReminder
  } = usePushNotifications();

  const [activeTab, setActiveTab] = useState('incubation');
  const [isLoading, setIsLoading] = useState(false);

  // Kuluçka form state
  const [incubationForm, setIncubationForm] = useState({
    breedingId: '',
    eggCount: 1,
    startDate: new Date(),
    expectedHatchDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000), // 18 gün sonra
    temperatureCheck: true,
    humidityCheck: true,
    eggTurning: true
  });

  // Beslenme form state
  const [feedingForm, setFeedingForm] = useState({
    chickId: '',
    birdId: '',
    foodType: '',
    frequency: 'daily' as 'daily' | 'twice_daily' | 'weekly',
    time: '08:00',
    notes: ''
  });

  // Veteriner form state
  const [veterinaryForm, setVeterinaryForm] = useState({
    birdId: '',
    appointmentType: 'checkup' as 'checkup' | 'vaccination' | 'treatment' | 'emergency',
    date: new Date(Date.now() + 24 * 60 * 60 * 1000), // yarın
    vetName: '',
    notes: ''
  });

  // Üreme form state
  const [breedingForm, setBreedingForm] = useState({
    breedingId: '',
    pairName: '',
    cycleType: 'preparation' as 'preparation' | 'mating' | 'egg_laying' | 'incubation' | 'hatching',
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 1 hafta sonra
  });

  // Etkinlik form state
  const [eventForm, setEventForm] = useState({
    eventId: '',
    eventType: 'custom' as 'competition' | 'exhibition' | 'show' | 'meeting' | 'custom',
    title: '',
    date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 hafta sonra
    location: '',
    description: ''
  });

  const { t } = useLanguage();
  const { validateNotificationForm, validateVeterinaryAppointment } = useFormValidation();

  const handleSubmit = async () => {
    setIsLoading(true);
    try {
      switch (activeTab) {
        case 'incubation':
          // Kuluçka bildirimi doğrulama
          const incubationData = {
            type: 'incubation' as const,
            title: `Kuluçka Hatırlatıcısı - ${incubationForm.breedingId}`,
            date: incubationForm.startDate,
            description: `${incubationForm.eggCount} yumurta için kuluçka takibi`
          };
          validateNotificationForm(incubationData);
          await createIncubationReminder(incubationForm);
          break;
          
        case 'feeding':
          // Beslenme bildirimi doğrulama
          const feedingData = {
            type: 'feeding' as const,
            title: `Beslenme Hatırlatıcısı`,
            date: new Date(),
            time: feedingForm.time,
            description: feedingForm.notes
          };
          validateNotificationForm(feedingData);
          await createFeedingReminder(feedingForm);
          break;
          
        case 'veterinary':
          // Veteriner randevu doğrulama
          const veterinaryData = {
            birdId: veterinaryForm.birdId,
            appointmentType: veterinaryForm.appointmentType,
            date: veterinaryForm.date,
            vetName: veterinaryForm.vetName,
            notes: veterinaryForm.notes
          };
          validateVeterinaryAppointment(veterinaryData);
          await createVeterinaryReminder(veterinaryForm);
          break;
          
        case 'breeding':
          // Üreme bildirimi doğrulama
          const breedingData = {
            type: 'breeding' as const,
            title: `Üreme Hatırlatıcısı - ${breedingForm.pairName}`,
            date: breedingForm.dueDate,
            description: `${breedingForm.cycleType} aşaması`
          };
          validateNotificationForm(breedingData);
          await createBreedingReminder(breedingForm);
          break;
          
        case 'event':
          // Etkinlik bildirimi doğrulama
          const eventData = {
            type: 'event' as const,
            title: eventForm.title,
            date: eventForm.date,
            description: eventForm.description
          };
          validateNotificationForm(eventData);
          await createEventReminder(eventForm);
          break;
      }
      
      toast({
        title: 'Başarılı',
        description: 'Bildirim başarıyla oluşturuldu.',
      });
      
      onOpenChange(false);
    } catch (error) {
      console.error('Error creating notification:', error);
      toast({
        title: 'Hata',
        description: error instanceof Error ? error.message : 'Bildirim oluşturulurken bir hata oluştu.',
        variant: 'destructive'
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleDateChange = (date: Date, formType: string) => {
    switch (formType) {
      case 'incubation':
        setIncubationForm(prev => ({ ...prev, startDate: date }));
        break;
      case 'veterinary':
        setVeterinaryForm(prev => ({ ...prev, date }));
        break;
      case 'breeding':
        setBreedingForm(prev => ({ ...prev, dueDate: date }));
        break;
      case 'event':
        setEventForm(prev => ({ ...prev, date }));
        break;
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl max-h-[90vh] overflow-y-auto" aria-describedby="create-notification-description">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Plus className="h-5 w-5" />
            Yeni Hatırlatıcı Oluştur
          </DialogTitle>
          <DialogDescription>
            Kuluçka, beslenme, veteriner veya etkinlik hatırlatıcısı oluşturun
          </DialogDescription>
          <div id="create-notification-description" className="sr-only">
            Bildirim oluşturma formu
          </div>
        </DialogHeader>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-5">
            <TabsTrigger value="incubation">🥚 Kuluçka</TabsTrigger>
            <TabsTrigger value="feeding">🍽️ Beslenme</TabsTrigger>
            <TabsTrigger value="veterinary">🏥 Veteriner</TabsTrigger>
            <TabsTrigger value="breeding">❤️ Üreme</TabsTrigger>
            <TabsTrigger value="event">📅 Etkinlik</TabsTrigger>
          </TabsList>

          <TabsContent value="incubation" className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="breedingId">Üreme ID</Label>
                <Input
                  id="breedingId"
                  value={incubationForm.breedingId}
                  onChange={(e) => setIncubationForm(prev => ({ ...prev, breedingId: e.target.value }))}
                  placeholder="Üreme kaydı ID'si"
                />
              </div>
              <div>
                <Label htmlFor="eggCount">Yumurta Sayısı</Label>
                <Input
                  id="eggCount"
                  type="number"
                  min="1"
                  value={incubationForm.eggCount}
                  onChange={(e) => setIncubationForm(prev => ({ ...prev, eggCount: parseInt(e.target.value) || 1 }))}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Başlangıç Tarihi</Label>
                <Input
                  type="date"
                  value={formatDateForInput(incubationForm.startDate)}
                  onChange={(e) => handleDateChange(new Date(e.target.value), 'incubation')}
                  max={formatDateForInput(new Date())}
                />
              </div>
              <div>
                <Label>Beklenen Çıkım Tarihi</Label>
                <Input
                  type="date"
                  value={formatDateForInput(incubationForm.expectedHatchDate)}
                  onChange={(e) => setIncubationForm(prev => ({ ...prev, expectedHatchDate: new Date(e.target.value) }))}
                  min={formatDateForInput(incubationForm.startDate)}
                />
              </div>
            </div>

            <div className="space-y-3">
              <Label>Hatırlatıcı Türleri</Label>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="temperatureCheck"
                  checked={incubationForm.temperatureCheck}
                  onCheckedChange={(checked) => setIncubationForm(prev => ({ ...prev, temperatureCheck: !!checked }))}
                />
                <Label htmlFor="temperatureCheck">{t('common.temperatureCheck')} ({t('common.daily')})</Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="humidityCheck"
                  checked={incubationForm.humidityCheck}
                  onCheckedChange={(checked) => setIncubationForm(prev => ({ ...prev, humidityCheck: !!checked }))}
                />
                <Label htmlFor="humidityCheck">{t('common.humidityCheck')} ({t('common.daily')})</Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="eggTurning"
                  checked={incubationForm.eggTurning}
                  onCheckedChange={(checked) => setIncubationForm(prev => ({ ...prev, eggTurning: !!checked }))}
                />
                <Label htmlFor="eggTurning">Yumurta çevirme (günde 3x)</Label>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="feeding" className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="chickId">Yavru ID (Opsiyonel)</Label>
                <Input
                  id="chickId"
                  value={feedingForm.chickId}
                  onChange={(e) => setFeedingForm(prev => ({ ...prev, chickId: e.target.value }))}
                  placeholder="Yavru ID'si"
                />
              </div>
              <div>
                <Label htmlFor="birdId">Kuş ID (Opsiyonel)</Label>
                <Input
                  id="birdId"
                  value={feedingForm.birdId}
                  onChange={(e) => setFeedingForm(prev => ({ ...prev, birdId: e.target.value }))}
                  placeholder="Kuş ID'si"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="foodType">Yem Türü</Label>
                <Input
                  id="foodType"
                  value={feedingForm.foodType}
                  onChange={(e) => setFeedingForm(prev => ({ ...prev, foodType: e.target.value }))}
                  placeholder="Örn: Tohum, meyve, vitamin"
                />
              </div>
              <div>
                <Label htmlFor="feedingTime">Saat</Label>
                <Input
                  id="feedingTime"
                  type="time"
                  value={feedingForm.time}
                  onChange={(e) => setFeedingForm(prev => ({ ...prev, time: e.target.value }))}
                />
              </div>
            </div>

            <div>
              <Label htmlFor="feedingFrequency">Sıklık</Label>
              <Select
                value={feedingForm.frequency}
                onValueChange={(value: 'daily' | 'twice_daily' | 'weekly') => 
                  setFeedingForm(prev => ({ ...prev, frequency: value }))
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="daily">{t('common.daily')}</SelectItem>
                  <SelectItem value="twice_daily">Günde 2 kez</SelectItem>
                  <SelectItem value="weekly">{t('common.weekly')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="feedingNotes">Notlar</Label>
              <Textarea
                id="feedingNotes"
                value={feedingForm.notes}
                onChange={(e) => setFeedingForm(prev => ({ ...prev, notes: e.target.value }))}
                placeholder="Ek notlar..."
              />
            </div>
          </TabsContent>

          <TabsContent value="veterinary" className="space-y-4">
            <div>
              <Label htmlFor="vetBirdId">Kuş ID (Opsiyonel)</Label>
              <Input
                id="vetBirdId"
                value={veterinaryForm.birdId}
                onChange={(e) => setVeterinaryForm(prev => ({ ...prev, birdId: e.target.value }))}
                placeholder="Kuş ID'si"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="appointmentType">Randevu Türü</Label>
                <Select
                  value={veterinaryForm.appointmentType}
                  onValueChange={(value: 'checkup' | 'vaccination' | 'treatment' | 'emergency') => 
                    setVeterinaryForm(prev => ({ ...prev, appointmentType: value }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="checkup">Kontrol</SelectItem>
                    <SelectItem value="vaccination">Aşılama</SelectItem>
                    <SelectItem value="treatment">Tedavi</SelectItem>
                    <SelectItem value="emergency">Acil</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="vetName">Veteriner Adı</Label>
                <Input
                  id="vetName"
                  value={veterinaryForm.vetName}
                  onChange={(e) => setVeterinaryForm(prev => ({ ...prev, vetName: e.target.value }))}
                  placeholder="Veteriner adı"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Randevu Tarihi</Label>
                <Input
                  type="date"
                  value={formatDateForInput(veterinaryForm.date)}
                  onChange={(e) => handleDateChange(new Date(e.target.value), 'veterinary')}
                  min={formatDateForInput(new Date())}
                />
              </div>
              <div>
                <Label>Randevu Saati</Label>
                <Input
                  type="time"
                  value={formatTimeForInput(veterinaryForm.date)}
                  onChange={(e) => {
                    const [hours, minutes] = e.target.value.split(':');
                    const newDate = new Date(veterinaryForm.date);
                    newDate.setHours(parseInt(hours || '0'), parseInt(minutes || '0'));
                    setVeterinaryForm(prev => ({ ...prev, date: newDate }));
                  }}
                />
              </div>
            </div>

            <div>
              <Label htmlFor="vetNotes">Notlar</Label>
              <Textarea
                id="vetNotes"
                value={veterinaryForm.notes}
                onChange={(e) => setVeterinaryForm(prev => ({ ...prev, notes: e.target.value }))}
                placeholder="Randevu notları..."
              />
            </div>
          </TabsContent>

          <TabsContent value="breeding" className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="breedingId">Üreme ID</Label>
                <Input
                  id="breedingId"
                  value={breedingForm.breedingId}
                  onChange={(e) => setBreedingForm(prev => ({ ...prev, breedingId: e.target.value }))}
                  placeholder="Üreme kaydı ID'si"
                />
              </div>
              <div>
                <Label htmlFor="pairName">Çift Adı</Label>
                <Input
                  id="pairName"
                  value={breedingForm.pairName}
                  onChange={(e) => setBreedingForm(prev => ({ ...prev, pairName: e.target.value }))}
                  placeholder="Örn: Mavi x Sarı"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="cycleType">Döngü Türü</Label>
                <Select
                  value={breedingForm.cycleType}
                  onValueChange={(value: 'preparation' | 'mating' | 'egg_laying' | 'incubation' | 'hatching') => 
                    setBreedingForm(prev => ({ ...prev, cycleType: value }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="preparation">Hazırlık</SelectItem>
                    <SelectItem value="mating">Çiftleşme</SelectItem>
                    <SelectItem value="egg_laying">Yumurtlama</SelectItem>
                    <SelectItem value="incubation">Kuluçka</SelectItem>
                    <SelectItem value="hatching">Çıkım</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label>Beklenen Tarih</Label>
                <Input
                  type="date"
                  value={format(breedingForm.dueDate, 'yyyy-MM-dd')}
                  onChange={(e) => handleDateChange(new Date(e.target.value), 'breeding')}
                />
              </div>
            </div>
          </TabsContent>

          <TabsContent value="event" className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="eventId">Etkinlik ID</Label>
                <Input
                  id="eventId"
                  value={eventForm.eventId}
                  onChange={(e) => setEventForm(prev => ({ ...prev, eventId: e.target.value }))}
                  placeholder="Etkinlik ID'si"
                />
              </div>
              <div>
                <Label htmlFor="eventType">Etkinlik Türü</Label>
                <Select
                  value={eventForm.eventType}
                  onValueChange={(value: 'competition' | 'exhibition' | 'show' | 'meeting' | 'custom') => 
                    setEventForm(prev => ({ ...prev, eventType: value }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="competition">Yarışma</SelectItem>
                    <SelectItem value="exhibition">Sergi</SelectItem>
                    <SelectItem value="show">Gösteri</SelectItem>
                    <SelectItem value="meeting">Toplantı</SelectItem>
                    <SelectItem value="custom">Özel</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div>
              <Label htmlFor="eventTitle">Etkinlik Adı</Label>
              <Input
                id="eventTitle"
                value={eventForm.title}
                onChange={(e) => setEventForm(prev => ({ ...prev, title: e.target.value }))}
                placeholder="Etkinlik adı"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Etkinlik Tarihi</Label>
                <Input
                  type="date"
                  value={formatDateForInput(eventForm.date)}
                  onChange={(e) => handleDateChange(new Date(e.target.value), 'event')}
                  min={formatDateForInput(new Date())}
                />
              </div>
              <div>
                <Label>Etkinlik Saati</Label>
                <Input
                  type="time"
                  value={formatTimeForInput(eventForm.date)}
                  onChange={(e) => {
                    const [hours, minutes] = e.target.value.split(':');
                    const newDate = new Date(eventForm.date);
                    newDate.setHours(parseInt(hours || '0'), parseInt(minutes || '0'));
                    setEventForm(prev => ({ ...prev, date: newDate }));
                  }}
                />
              </div>
            </div>

            <div>
              <Label htmlFor="eventLocation">Yer</Label>
              <Input
                id="eventLocation"
                value={eventForm.location}
                onChange={(e) => setEventForm(prev => ({ ...prev, location: e.target.value }))}
                placeholder="Etkinlik yeri"
              />
            </div>

            <div>
              <Label htmlFor="eventDescription">Açıklama</Label>
              <Textarea
                id="eventDescription"
                value={eventForm.description}
                onChange={(e) => setEventForm(prev => ({ ...prev, description: e.target.value }))}
                placeholder="Etkinlik açıklaması..."
              />
            </div>
          </TabsContent>
        </Tabs>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            İptal
          </Button>
          <Button onClick={handleSubmit} disabled={isLoading}>
            {isLoading ? 'Oluşturuluyor...' : 'Hatırlatıcı Oluştur'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}; 