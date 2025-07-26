import React, { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Target } from 'lucide-react';

interface GoalSettingModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (goal: GoalData) => void;
  currentSuccessRate: number;
}

export interface GoalData {
  targetSuccessRate: number;
  targetDate: string;
  goalType: 'short' | 'medium' | 'long';
  description: string;
}

const GoalSettingModal: React.FC<GoalSettingModalProps> = ({
  isOpen,
  onClose,
  onSave,
  currentSuccessRate
}) => {
  const [goalData, setGoalData] = useState<GoalData>({
    targetSuccessRate: Math.min(100, currentSuccessRate + 10),
    targetDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] || '', // 30 gün sonra
    goalType: 'medium',
    description: ''
  });

  const handleSave = () => {
    onSave(goalData);
    onClose();
  };

  const getSuggestedGoal = (type: 'short' | 'medium' | 'long') => {
    switch (type) {
      case 'short':
        return Math.min(100, currentSuccessRate + 5);
      case 'medium':
        return Math.min(100, currentSuccessRate + 10);
      case 'long':
        return Math.min(100, currentSuccessRate + 20);
      default:
        return currentSuccessRate + 10;
    }
  };

  const handleGoalTypeChange = (type: string) => {
    const goalType = type as 'short' | 'medium' | 'long';
    setGoalData(prev => ({
      ...prev,
      goalType,
      targetSuccessRate: getSuggestedGoal(goalType)
    }));
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[425px]" aria-describedby="goal-setting-description">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Target className="w-5 h-5" />
            Hedef Belirle
          </DialogTitle>
          <DialogDescription>
            Üreme performansınız için yeni bir hedef belirleyin ve takip edin.
          </DialogDescription>
          <div id="goal-setting-description" className="sr-only">
            Üreme performansı hedef belirleme formu
          </div>
        </DialogHeader>

        <div className="grid gap-4 py-4">
          {/* Mevcut Durum */}
          <div className="p-3 rounded-lg bg-muted/50">
            <div className="text-sm font-medium mb-1">Mevcut Başarı Oranı</div>
            <div className="text-2xl font-bold text-primary">%{currentSuccessRate}</div>
          </div>

          {/* Hedef Türü */}
          <div className="grid gap-2">
            <Label htmlFor="goalType">Hedef Türü</Label>
            <Select value={goalData.goalType} onValueChange={handleGoalTypeChange}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="short">Kısa Vadeli (1 ay)</SelectItem>
                <SelectItem value="medium">Orta Vadeli (3 ay)</SelectItem>
                <SelectItem value="long">Uzun Vadeli (6 ay)</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Hedef Başarı Oranı */}
          <div className="grid gap-2">
            <Label htmlFor="targetRate">Hedef Başarı Oranı (%)</Label>
            <Input
              id="targetRate"
              type="number"
              min="0"
              max="100"
              value={goalData.targetSuccessRate}
              onChange={(e) => setGoalData(prev => ({
                ...prev,
                targetSuccessRate: parseInt(e.target.value) || 0
              }))}
            />
            <div className="text-xs text-muted-foreground">
              Önerilen: %{getSuggestedGoal(goalData.goalType)}
            </div>
          </div>

          {/* Hedef Tarihi */}
          <div className="grid gap-2">
            <Label htmlFor="targetDate">Hedef Tarihi</Label>
            <Input
              id="targetDate"
              type="date"
              value={goalData.targetDate}
              onChange={(e) => setGoalData(prev => ({
                ...prev,
                targetDate: e.target.value
              }))}
            />
          </div>

          {/* Açıklama */}
          <div className="grid gap-2">
            <Label htmlFor="description">Açıklama (İsteğe bağlı)</Label>
            <Input
              id="description"
              placeholder="Hedefiniz hakkında notlar..."
              value={goalData.description}
              onChange={(e) => setGoalData(prev => ({
                ...prev,
                description: e.target.value
              }))}
            />
          </div>

          {/* Hedef Özeti */}
          <div className="p-3 rounded-lg bg-blue-50 dark:bg-blue-950/20">
            <div className="text-sm font-medium mb-2">Hedef Özeti</div>
            <div className="space-y-1 text-sm">
              <div className="flex justify-between">
                <span>Mevcut:</span>
                <span className="font-medium">%{currentSuccessRate}</span>
              </div>
              <div className="flex justify-between">
                <span>Hedef:</span>
                <span className="font-medium text-blue-600">%{goalData.targetSuccessRate}</span>
              </div>
              <div className="flex justify-between">
                <span>Artış:</span>
                <span className="font-medium text-green-600">
                  +{goalData.targetSuccessRate - currentSuccessRate}%
                </span>
              </div>
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            İptal
          </Button>
          <Button onClick={handleSave} className="gap-2">
            <Target className="w-4 h-4" />
            Hedefi Kaydet
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default GoalSettingModal; 