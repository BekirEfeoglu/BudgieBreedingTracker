import { useState, useRef } from 'react';
import React from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { Calendar as CalendarIcon, X, Plus, Trash2, Edit } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { toast } from '@/hooks/use-toast';
import { useLanguage } from '@/contexts/LanguageContext';
import { Egg } from '@/types';

const breedingFormSchema = z.object({
  nestName: z.string().min(1, 'Yuva adı zorunludur'),
  femaleBirdId: z.string().min(1, 'Dişi kuş seçimi zorunludur'),
  maleBirdId: z.string().min(1, 'Erkek kuş seçimi zorunludur'),
  startDate: z.date({
    required_error: 'Başlangıç tarihi zorunludur'
  }),
  notes: z.string().optional()
}).refine((data) => data.femaleBirdId !== data.maleBirdId, {
  message: 'Dişi ve erkek kuş aynı olamaz',
  path: ['maleBirdId']
});

type BreedingFormData = z.infer<typeof breedingFormSchema>;

interface Bird {
  id: string;
  name: string;
  gender: 'male' | 'female' | 'unknown';
}

interface BreedingFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: BreedingFormData & { eggs: Egg[] }) => void;
  existingBirds: Bird[];
  existingBreeding: Array<{ nestName: string }>;
  editingBreeding?: any;
  editingEgg?: Egg | null;
}

const nestNameSuggestions = [
  'Yuva 1', 'Yuva 2', 'Yuva 3', 'Yuva A', 'Yuva B', 'Yuva C',
  'Kuluçka 1', 'Kuluçka 2', 'Kuluçka A', 'Kuluçka B',
  'Ana Yuva', 'Doğu Yuvası', 'Batı Yuvası'
];

const eggStatusOptions = [
  { value: 'unknown', label: 'Belirsiz', color: 'bg-gray-400' },
  { value: 'fertile', label: 'Dolu', color: 'bg-green-500' },
  { value: 'infertile', label: 'Boş', color: 'bg-red-500' },
  { value: 'hatched', label: 'Çıktı', color: 'bg-blue-500' }
];

interface EggFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: Partial<Egg>) => void;
  existingBirds: Bird[];
  editingEgg?: Egg | null;
  nextEggNumber: number;
}

const BreedingForm = ({ 
  isOpen, 
  onClose, 
  onSave, 
  existingBirds, 
  existingBreeding, 
  editingBreeding, 
  editingEgg 
}: BreedingFormProps) => {
  const [eggs, setEggs] = useState<Egg[]>([]);
  const [nextEggNumber, setNextEggNumber] = useState(1);
  const [editingEggState, setEditingEggState] = useState<Egg | null>(null);
  const [isEggFormOpen, setIsEggFormOpen] = useState(false);

  const form = useForm<BreedingFormData>({
    resolver: zodResolver(breedingFormSchema),
    defaultValues: {
      nestName: '',
      femaleBirdId: '',
      maleBirdId: '',
      startDate: undefined,
      notes: ''
    }
  });

  React.useEffect(() => {
    if (editingBreeding) {
      const femaleBird = existingBirds.find(b => b.name === editingBreeding.femaleBird);
      const maleBird = existingBirds.find(b => b.name === editingBreeding.maleBird);
      
      form.setValue('nestName', editingBreeding.nestName);
      form.setValue('femaleBirdId', femaleBird?.id || '');
      form.setValue('maleBirdId', maleBird?.id || '');
      form.setValue('startDate', new Date(editingBreeding.startDate));
      form.setValue('notes', editingBreeding.notes || '');
      
      setEggs(editingBreeding.eggs || []);
      const maxEggNumber = Math.max(0, ...(editingBreeding.eggs || []).map((egg: Egg) => egg.number));
      setNextEggNumber(maxEggNumber + 1);
    }
  }, [editingBreeding, form, existingBirds]);

  React.useEffect(() => {
    if (editingEgg) {
      setEditingEggState(editingEgg);
      setIsEggFormOpen(true);
    }
  }, [editingEgg]);

  const generateNestName = () => {
    const usedNames = existingBreeding.map(b => b.nestName);
    const availableNames = nestNameSuggestions.filter(name => !usedNames.includes(name));
    
    if (availableNames.length > 0) {
      const randomName = availableNames[Math.floor(Math.random() * availableNames.length)];
      form.setValue('nestName', randomName);
    } else {
      const nextNumber = existingBreeding.length + 1;
      form.setValue('nestName', `Yuva ${nextNumber}`);
    }
  };

  const addEgg = () => {
    setEditingEggState(null);
    setIsEggFormOpen(true);
  };

  const editEgg = (egg: Egg) => {
    setEditingEggState(egg);
    setIsEggFormOpen(true);
  };

  const saveEgg = (eggData: Partial<Egg>) => {
    if (editingEggState) {
      setEggs(prev => prev.map(egg => 
        egg.id === editingEggState.id ? { ...egg, ...eggData } : egg
      ));
      toast({
        title: 'Başarılı',
        description: 'Yumurta başarıyla güncellendi'
      });
    } else {
      const newEgg: Egg = {
        id: Date.now().toString(),
        number: nextEggNumber,
        status: 'unknown',
        dateAdded: new Date().toISOString().split('T')[0],
        ...eggData
      };
      setEggs(prev => [...prev, newEgg]);
      setNextEggNumber(prev => prev + 1);
      toast({
        title: 'Başarılı',
        description: 'Yumurta başarıyla eklendi'
      });
    }
    setIsEggFormOpen(false);
    setEditingEggState(null);
  };

  const removeEgg = (eggId: string) => {
    const eggToDelete = eggs.find(egg => egg.id === eggId);
    if (window.confirm(`${eggToDelete?.number}. yumurtayı silmek istediğinizden emin misiniz?`)) {
      setEggs(prev => prev.filter(egg => egg.id !== eggId));
      toast({
        title: 'Başarılı',
        description: 'Yumurta başarıyla silindi'
      });
    }
  };

  const onSubmit = (data: BreedingFormData) => {
    if (data.startDate && data.startDate > new Date()) {
      toast({
        title: 'Hata',
        description: 'Başlangıç tarihi gelecekte olamaz',
        variant: 'destructive'
      });
      return;
    }

    onSave({ ...data, eggs });
    
    if (editingBreeding) {
      toast({
        title: 'Başarılı',
        description: 'Kuluçka başarıyla güncellendi'
      });
    } else {
      toast({
        title: 'Başarılı',
        description: 'Kuluçka başarıyla eklendi'
      });
    }
    
    handleClose();
  };

  const handleClose = () => {
    form.reset();
    setEggs([]);
    setNextEggNumber(1);
    setEditingEggState(null);
    setIsEggFormOpen(false);
    onClose();
  };

  const femaleBirds = existingBirds.filter(bird => bird.gender === 'female');
  const maleBirds = existingBirds.filter(bird => bird.gender === 'male');

  const selectedFemale = form.watch('femaleBirdId');
  const selectedMale = form.watch('maleBirdId');

  return (
    <>
      <Dialog open={isOpen} onOpenChange={handleClose}>
        <DialogContent className="max-w-2xl mx-auto max-h-[90vh] overflow-y-auto" aria-describedby="breeding-form-description">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold text-center flex items-center justify-between">
              {editingBreeding ? 'Kuluçkayı Düzenle' : 'Yeni Kuluçka Ekle'}
              <Button variant="ghost" size="icon" onClick={handleClose}>
                <X className="w-4 h-4" />
              </Button>
            </DialogTitle>
            <DialogDescription>
              Kuluçka bilgilerini girin ve yumurtaları ekleyin.
            </DialogDescription>
          </DialogHeader>
          <div id="breeding-form-description" className="sr-only">
            Kuluçka ekleme/düzenleme formu
          </div>
          
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              
              <FormField
                control={form.control}
                name="nestName"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className="flex items-center justify-between">
                      Yuva/Kuluçka Adı *
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={generateNestName}
                      >
                        Öneri Al
                      </Button>
                    </FormLabel>
                    <FormControl>
                      <Input 
                        {...field}
                        placeholder="Yuva adını girin"
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="femaleBirdId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Dişi Kuş *</FormLabel>
                    <FormControl>
                      <Select 
                        value={field.value || undefined} 
                        onValueChange={(value) => {
                          field.onChange(value);
                          if (value === selectedMale) {
                            form.setValue('maleBirdId', '');
                          }
                        }}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Dişi kuş seçin" />
                        </SelectTrigger>
                        <SelectContent>
                          {femaleBirds.map((bird) => (
                            <SelectItem key={bird.id} value={bird.id}>
                              {bird.name} ♀️
                            </SelectItem>
                          ))}
                          {femaleBirds.length === 0 && (
                            <SelectItem value="no-females" disabled>
                              Dişi kuş bulunamadı
                            </SelectItem>
                          )}
                        </SelectContent>
                      </Select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="maleBirdId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Erkek Kuş *</FormLabel>
                    <FormControl>
                      <Select 
                        value={field.value || undefined} 
                        onValueChange={(value) => {
                          field.onChange(value);
                          if (value === selectedFemale) {
                            form.setValue('femaleBirdId', '');
                          }
                        }}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Erkek kuş seçin" />
                        </SelectTrigger>
                        <SelectContent>
                          {maleBirds.map((bird) => (
                            <SelectItem key={bird.id} value={bird.id}>
                              {bird.name} ♂️
                            </SelectItem>
                          ))}
                          {maleBirds.length === 0 && (
                            <SelectItem value="no-males" disabled>
                              Erkek kuş bulunamadı
                            </SelectItem>
                          )}
                        </SelectContent>
                      </Select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="startDate"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Başlangıç Tarihi *</FormLabel>
                    <Popover>
                      <PopoverTrigger asChild>
                        <FormControl>
                          <Button
                            variant="outline"
                            className={cn(
                              "w-full pl-3 text-left font-normal",
                              !field.value && "text-muted-foreground"
                            )}
                          >
                            {field.value ? (
                              format(field.value, "dd/MM/yyyy")
                            ) : (
                              <span>Tarih seçin</span>
                            )}
                            <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                          </Button>
                        </FormControl>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0" align="start">
                        <Calendar
                          mode="single"
                          selected={field.value}
                          onSelect={field.onChange}
                          disabled={(date) => date > new Date()}
                          initialFocus
                          className="pointer-events-auto"
                        />
                      </PopoverContent>
                    </Popover>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="notes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Notlar</FormLabel>
                    <FormControl>
                      <Textarea 
                        {...field}
                        placeholder="Ek bilgiler, gözlemler vb."
                        rows={3}
                      />
                    </FormControl>
                  </FormItem>
                )}
              />

              {/* Yumurta Listesi */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <Label className="text-sm font-medium">Yumurtalar (İsteğe Bağlı)</Label>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={addEgg}
                    className="touch-button"
                  >
                    <Plus className="w-4 h-4 mr-1" />
                    Yumurta Ekle
                  </Button>
                </div>

                {eggs.length > 0 && (
                  <div className="space-y-2 max-h-60 overflow-y-auto mobile-scroll">
                    {eggs.map((egg) => {
                      const motherBird = existingBirds.find(b => b.id === egg.motherId);
                      const fatherBird = existingBirds.find(b => b.id === egg.fatherId);
                      const statusOption = eggStatusOptions.find(opt => opt.value === egg.status);
                      
                      return (
                        <div key={egg.id} className="flex items-center gap-2 p-3 border rounded-lg bg-muted/20 animate-fade-in">
                          <div className="flex items-center gap-3 flex-1">
                            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-sm font-medium">
                              {egg.number}
                            </div>
                            
                            <div className="flex-1 space-y-1">
                              <div className="flex items-center gap-2">
                                <Badge variant="secondary" className={`text-white ${statusOption?.color}`}>
                                  {statusOption?.label}
                                </Badge>
                                <span className="text-xs text-muted-foreground">
                                  {new Date(egg.dateAdded).toLocaleDateString('tr-TR')}
                                </span>
                              </div>
                              
                              {(motherBird || fatherBird) && (
                                <div className="text-xs text-muted-foreground">
                                  {motherBird && `♀️ ${motherBird.name}`}
                                  {motherBird && fatherBird && ' • '}
                                  {fatherBird && `♂️ ${fatherBird.name}`}
                                </div>
                              )}
                            </div>
                          </div>

                          <div className="flex gap-1">
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              onClick={() => editEgg(egg)}
                              className="touch-button hover-scale"
                            >
                              <Edit className="w-4 h-4" />
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              onClick={() => removeEgg(egg.id)}
                              className="text-destructive hover:text-destructive touch-button hover-scale"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                {eggs.length === 0 && (
                  <div className="text-center py-4 text-muted-foreground">
                    <div className="text-2xl mb-2">🥚</div>
                    <p className="text-sm">Henüz yumurta eklenmemiş.</p>
                  </div>
                )}
              </div>

              {/* Butonlar */}
              <div className="flex space-x-2 pt-4 safe-area-bottom">
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleClose}
                  className="flex-1 touch-button"
                >
                  Vazgeç
                </Button>
                <Button
                  type="submit"
                  className="flex-1 budgie-button touch-button"
                  disabled={!form.formState.isValid || form.formState.isSubmitting}
                >
                  {editingBreeding ? 'Güncelle' : 'Kaydet'}
                </Button>
              </div>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      {/* Yumurta Ekleme/Düzenleme Modal */}
      <EggForm
        isOpen={isEggFormOpen}
        onClose={() => {
          setIsEggFormOpen(false);
          setEditingEggState(null);
        }}
        onSave={saveEgg}
        existingBirds={existingBirds}
        editingEgg={editingEggState}
        nextEggNumber={nextEggNumber}
      />
    </>
  );
};

const EggForm = ({ isOpen, onClose, onSave, existingBirds, editingEgg, nextEggNumber }: EggFormProps) => {
  const [formData, setFormData] = useState({
    status: 'unknown' as Egg['status'],
    dateAdded: new Date().toISOString().split('T')[0],
    motherId: '',
    fatherId: ''
  });

  const [errors, setErrors] = useState<{[key: string]: string}>({});

  const femaleBirds = existingBirds.filter(bird => bird.gender === 'female');
  const maleBirds = existingBirds.filter(bird => bird.gender === 'male');

  React.useEffect(() => {
    if (editingEgg) {
      setFormData({
        status: editingEgg.status,
        dateAdded: editingEgg.dateAdded,
        motherId: editingEgg.motherId || '',
        fatherId: editingEgg.fatherId || ''
      });
    } else {
      setFormData({
        status: 'unknown',
        dateAdded: new Date().toISOString().split('T')[0],
        motherId: '',
        fatherId: ''
      });
    }
    setErrors({});
  }, [editingEgg, isOpen]);

  const validateForm = () => {
    const newErrors: {[key: string]: string} = {};

    if (!formData.status) {
      newErrors.status = 'Durum seçimi zorunludur';
    }

    if (!formData.dateAdded) {
      newErrors.dateAdded = 'Tarih seçimi zorunludur';
    } else if (new Date(formData.dateAdded) > new Date()) {
      newErrors.dateAdded = 'Yumurta tarihi gelecekte olamaz';
    }

    if (formData.motherId && formData.fatherId && formData.motherId === formData.fatherId) {
      newErrors.parents = 'Anne ve baba aynı kuş olamaz';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      toast({
        title: 'Hata',
        description: 'Lütfen tüm zorunlu alanları doğru şekilde doldurun',
        variant: 'destructive'
      });
      return;
    }

    onSave({
      ...formData,
      motherId: formData.motherId || undefined,
      fatherId: formData.fatherId || undefined
    });
  };

  const handleDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setFormData(prev => ({ ...prev, dateAdded: value }));
    
    if (errors.dateAdded) {
      setErrors(prev => ({ ...prev, dateAdded: '' }));
    }
  };

  const handleStatusChange = (value: string) => {
    setFormData(prev => ({ ...prev, status: value as Egg['status'] }));
    
    if (errors.status) {
      setErrors(prev => ({ ...prev, status: '' }));
    }
  };

  const handleParentChange = (field: 'motherId' | 'fatherId', value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    
    if (errors.parents) {
      setErrors(prev => ({ ...prev, parents: '' }));
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md mx-auto max-h-[90vh] overflow-y-auto" aria-describedby="egg-form-description">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold text-center flex items-center justify-between">
            {editingEgg ? 'Yumurtayı Düzenle' : 'Yeni Yumurta Ekle'}
            <Button variant="ghost" size="icon" onClick={onClose} className="touch-button">
              <X className="w-4 h-4" />
            </Button>
          </DialogTitle>
        </DialogHeader>
        <div id="egg-form-description" className="sr-only">
            Yumurta ekleme/düzenleme formu
          </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label className="text-sm font-medium text-primary">
              Yumurta Numarası: {editingEgg ? editingEgg.number : nextEggNumber}
            </Label>
          </div>

          <div>
            <Label htmlFor="status" className="text-sm font-medium">
              Durum * {errors.status && <span className="text-destructive text-xs ml-2">{errors.status}</span>}
            </Label>
            <Select 
              value={formData.status} 
              onValueChange={handleStatusChange}
            >
              <SelectTrigger className={cn("touch-button", errors.status && "border-destructive")}>
                <SelectValue placeholder="Durum seçin" />
              </SelectTrigger>
              <SelectContent>
                {eggStatusOptions.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    <div className="flex items-center gap-2">
                      <div className={`w-3 h-3 rounded-full ${option.color}`} />
                      {option.label}
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label htmlFor="dateAdded" className="text-sm font-medium">
              Tarih * {errors.dateAdded && <span className="text-destructive text-xs ml-2">{errors.dateAdded}</span>}
            </Label>
            <Input
              id="dateAdded"
              type="date"
              value={formData.dateAdded}
              onChange={handleDateChange}
              max={new Date().toISOString().split('T')[0]}
              required
              className={cn("touch-button", errors.dateAdded && "border-destructive")}
            />
          </div>

          <div>
            <Label htmlFor="motherId" className="text-sm font-medium">Anne (İsteğe Bağlı)</Label>
            <Select 
              value={formData.motherId} 
              onValueChange={(value) => handleParentChange('motherId', value)}
            >
              <SelectTrigger className="touch-button">
                <SelectValue placeholder="Anne seçin" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="no-mother">Seçilmedi</SelectItem>
                {femaleBirds.map((bird) => (
                  <SelectItem key={bird.id} value={bird.id}>
                    {bird.name} ♀️
                  </SelectItem>
                ))}
                {femaleBirds.length === 0 && (
                  <SelectItem value="no-females" disabled>
                    Dişi kuş bulunamadı
                  </SelectItem>
                )}
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label htmlFor="fatherId" className="text-sm font-medium">
              Baba (İsteğe Bağlı)
              {errors.parents && <span className="text-destructive text-xs ml-2">{errors.parents}</span>}
            </Label>
            <Select 
              value={formData.fatherId} 
              onValueChange={(value) => handleParentChange('fatherId', value)}
            >
              <SelectTrigger className={cn("touch-button", errors.parents && "border-destructive")}>
                <SelectValue placeholder="Baba seçin" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="no-father">Seçilmedi</SelectItem>
                {maleBirds.map((bird) => (
                  <SelectItem key={bird.id} value={bird.id}>
                    {bird.name} ♂️
                  </SelectItem>
                ))}
                {maleBirds.length === 0 && (
                  <SelectItem value="no-males" disabled>
                    Erkek kuş bulunamadı
                  </SelectItem>
                )}
              </SelectContent>
            </Select>
          </div>

          <div className="flex space-x-2 pt-4 safe-area-bottom">
            <Button
              type="button"
              variant="outline"
              onClick={onClose}
              className="flex-1 touch-button"
            >
              Vazgeç
            </Button>
            <Button
              type="submit"
              className="flex-1 budgie-button touch-button"
            >
              {editingEgg ? 'Güncelle' : 'Kaydet'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default BreedingForm;
