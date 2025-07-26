import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { Filter, X, Calendar, Users, Target } from 'lucide-react';

interface FilterOptions {
  timeRange: '7d' | '30d' | '90d' | '1y' | 'all';
  gender: 'all' | 'male' | 'female' | 'unknown';
  ageRange: 'all' | 'young' | 'adult' | 'senior';
  status: 'all' | 'alive' | 'dead' | 'sold';
  breedingStatus: 'all' | 'active' | 'inactive' | 'successful' | 'failed';
  minSuccessRate: number;
  maxSuccessRate: number;
  includeChicks: boolean;
  includeEggs: boolean;
  includeIncubations: boolean;
}

interface AdvancedFiltersProps {
  filters: FilterOptions;
  onFiltersChange: (filters: FilterOptions) => void;
  onReset: () => void;
}

const AdvancedFilters: React.FC<AdvancedFiltersProps> = ({
  filters,
  onFiltersChange,
  onReset
}) => {
  const [isExpanded, setIsExpanded] = useState(false);

  const updateFilter = (key: keyof FilterOptions, value: any) => {
    onFiltersChange({
      ...filters,
      [key]: value
    });
  };

  const getActiveFiltersCount = () => {
    let count = 0;
    if (filters.timeRange !== '30d') count++;
    if (filters.gender !== 'all') count++;
    if (filters.ageRange !== 'all') count++;
    if (filters.status !== 'all') count++;
    if (filters.breedingStatus !== 'all') count++;
    if (filters.minSuccessRate > 0) count++;
    if (filters.maxSuccessRate < 100) count++;
    if (!filters.includeChicks) count++;
    if (!filters.includeEggs) count++;
    if (!filters.includeIncubations) count++;
    return count;
  };

  const activeFiltersCount = getActiveFiltersCount();

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Filter className="w-5 h-5" />
            Gelişmiş Filtreler
            {activeFiltersCount > 0 && (
              <Badge variant="secondary" className="ml-2 animate-bounce" title="Aktif filtre sayısı">
                {activeFiltersCount} aktif filtre
              </Badge>
            )}
          </CardTitle>
          <div className="flex items-center gap-2">
            {activeFiltersCount > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={onReset}
                className="text-xs"
                title="Tüm filtreleri sıfırla"
              >
                <X className="w-3 h-3 mr-1" />
                Filtreleri temizle
              </Button>
            )}
            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsExpanded(!isExpanded)}
              title={isExpanded ? 'Filtreleri gizle' : 'Filtreleri göster'}
            >
              {isExpanded ? 'Gizle' : 'Göster'}
            </Button>
          </div>
        </div>
      </CardHeader>
      
      {isExpanded && (
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {/* Zaman Aralığı */}
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Calendar className="w-4 h-4" />
                Zaman Aralığı
              </Label>
              <Select 
                value={filters.timeRange} 
                onValueChange={(value: '7d' | '30d' | '90d' | '1y' | 'all') => updateFilter('timeRange', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="7d">Son 7 gün</SelectItem>
                  <SelectItem value="30d">Son 30 gün</SelectItem>
                  <SelectItem value="90d">Son 90 gün</SelectItem>
                  <SelectItem value="1y">Son 1 yıl</SelectItem>
                  <SelectItem value="all">Tümü</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Cinsiyet */}
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Users className="w-4 h-4" />
                Cinsiyet
              </Label>
              <Select 
                value={filters.gender} 
                onValueChange={(value: 'all' | 'male' | 'female' | 'unknown') => updateFilter('gender', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tümü</SelectItem>
                  <SelectItem value="male">Erkek</SelectItem>
                  <SelectItem value="female">Dişi</SelectItem>
                  <SelectItem value="unknown">Bilinmiyor</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Yaş Aralığı */}
            <div className="space-y-2">
              <Label>Yaş Aralığı</Label>
              <Select 
                value={filters.ageRange} 
                onValueChange={(value: 'all' | 'young' | 'adult' | 'senior') => updateFilter('ageRange', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tümü</SelectItem>
                  <SelectItem value="young">Genç (0-1 yıl)</SelectItem>
                  <SelectItem value="adult">Yetişkin (1-5 yıl)</SelectItem>
                  <SelectItem value="senior">Yaşlı (5+ yıl)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Durum */}
            <div className="space-y-2">
              <Label>Durum</Label>
              <Select 
                value={filters.status} 
                onValueChange={(value: 'all' | 'alive' | 'dead' | 'sold') => updateFilter('status', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tümü</SelectItem>
                  <SelectItem value="alive">Yaşıyor</SelectItem>
                  <SelectItem value="dead">Öldü</SelectItem>
                  <SelectItem value="sold">Satıldı</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Üreme Durumu */}
            <div className="space-y-2">
              <Label>Üreme Durumu</Label>
              <Select 
                value={filters.breedingStatus} 
                onValueChange={(value: 'all' | 'active' | 'inactive' | 'successful' | 'failed') => updateFilter('breedingStatus', value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tümü</SelectItem>
                  <SelectItem value="active">Aktif</SelectItem>
                  <SelectItem value="inactive">Pasif</SelectItem>
                  <SelectItem value="successful">Başarılı</SelectItem>
                  <SelectItem value="failed">Başarısız</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Başarı Oranı */}
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Target className="w-4 h-4" />
                Başarı Oranı (%)
              </Label>
              <div className="flex gap-2">
                <Input
                  type="number"
                  placeholder="Min"
                  value={filters.minSuccessRate}
                  onChange={(e) => updateFilter('minSuccessRate', parseInt(e.target.value) || 0)}
                  className="w-20"
                />
                <span className="text-gray-500">-</span>
                <Input
                  type="number"
                  placeholder="Max"
                  value={filters.maxSuccessRate}
                  onChange={(e) => updateFilter('maxSuccessRate', parseInt(e.target.value) || 100)}
                  className="w-20"
                />
              </div>
            </div>
          </div>

          {/* Veri Türü Seçenekleri */}
          <div className="mt-6 space-y-3">
            <Label>Veri Türü</Label>
            <div className="flex flex-wrap gap-4">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="includeChicks"
                  checked={filters.includeChicks}
                  onCheckedChange={(checked) => updateFilter('includeChicks', checked)}
                />
                <Label htmlFor="includeChicks">Yavrular</Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="includeEggs"
                  checked={filters.includeEggs}
                  onCheckedChange={(checked) => updateFilter('includeEggs', checked)}
                />
                <Label htmlFor="includeEggs">Yumurtalar</Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="includeIncubations"
                  checked={filters.includeIncubations}
                  onCheckedChange={(checked) => updateFilter('includeIncubations', checked)}
                />
                <Label htmlFor="includeIncubations">Kuluçka</Label>
              </div>
            </div>
          </div>
        </CardContent>
      )}
    </Card>
  );
};

export default AdvancedFilters; 