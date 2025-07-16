import React from 'react';
import { Check, ChevronRight } from 'lucide-react';
import { Bird, Chick } from '@/types';
import { useLanguage } from '@/contexts/LanguageContext';

interface BirdListItemProps {
  bird: Bird | Chick;
  type: 'adult' | 'chick';
  isSelected: boolean;
  onSelect: (bird: Bird | Chick) => void;
}

const BirdListItem = ({ bird, type, isSelected, onSelect }: BirdListItemProps) => {
  const { t } = useLanguage();

  const getGenderIcon = (gender: string) => {
    switch (gender) {
      case 'male': return '🦜';
      case 'female': return '🐦';
      default: return '🐤';
    }
  };

  const getGenderColor = (gender: string) => {
    switch (gender) {
      case 'male': return 'text-blue-600 bg-blue-50 border-blue-200 dark:text-blue-400 dark:bg-blue-900/30 dark:border-blue-700';
      case 'female': return 'text-pink-600 bg-pink-50 border-pink-200 dark:text-pink-400 dark:bg-pink-900/30 dark:border-pink-700';
      default: return 'text-gray-600 bg-gray-50 border-gray-200 dark:text-gray-400 dark:bg-gray-900/30 dark:border-gray-700';
    }
  };

  const getGenderLabel = (gender: string) => {
    switch (gender) {
      case 'male': return 'Erkek';
      case 'female': return 'Dişi';
      default: return t('birds.unknown');
    }
  };

  const getAgeStage = (hatchDate: string) => {
    const birth = new Date(hatchDate);
    const now = new Date();
    const diffTime = now.getTime() - birth.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays <= 7) return { stage: 'Yeni Doğan', color: 'bg-pink-500' };
    if (diffDays <= 21) return { stage: 'Yuva Bebek', color: 'bg-orange-500' };
    if (diffDays <= 35) return { stage: 'Tüylenen', color: 'bg-yellow-500' };
    if (diffDays <= 60) return { stage: 'Uçmayı Öğrenen', color: 'bg-green-500' };
    return { stage: 'Genç', color: 'bg-blue-500' };
  };

  return (
    <div
      onClick={() => onSelect(bird)}
      className={`
        group relative p-3 rounded-xl border-2 transition-all duration-300 cursor-pointer
        hover:shadow-lg hover:scale-[1.02] active:scale-[0.98]
        ${isSelected
          ? 'border-primary bg-primary/10 shadow-md ring-2 ring-primary/20'
          : 'border-border hover:border-primary/50 hover:bg-accent/50'
        }
      `}
    >
      <div className="flex items-center gap-3">
        {/* Profil Fotoğrafı */}
        <div className="relative">
          {bird.photo ? (
            <img
              src={bird.photo}
              alt={bird.name}
              className="w-10 h-10 rounded-full object-cover border-2 border-border"
            />
          ) : (
            <div className={`
              w-10 h-10 rounded-full border-2 flex items-center justify-center text-sm
              ${getGenderColor(bird.gender)}
            `}>
              {type === 'chick' ? '🐣' : getGenderIcon(bird.gender)}
            </div>
          )}
          {isSelected && (
            <div className="absolute -top-1 -right-1 w-4 h-4 bg-primary rounded-full flex items-center justify-center">
              <Check className="w-2.5 h-2.5 text-white" />
            </div>
          )}
        </div>

        {/* Kuş Bilgileri */}
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold enhanced-text-primary text-sm truncate">
            {bird.name}
          </h3>
          <div className="flex items-center gap-1 mt-1">
            <span className={`
              px-1.5 py-0.5 rounded-full text-xs font-medium
              ${getGenderColor(bird.gender)}
            `}>
              {getGenderLabel(bird.gender)}
            </span>
            {type === 'chick' && 'hatchDate' in bird && (
              <span className={`
                px-1.5 py-0.5 rounded-full text-xs font-medium text-white
                ${getAgeStage(bird.hatchDate).color}
              `}>
                {getAgeStage(bird.hatchDate).stage}
              </span>
            )}
            {bird.ringNumber && (
              <span className="text-xs enhanced-text-secondary bg-muted px-1.5 py-0.5 rounded-full">
                {bird.ringNumber}
              </span>
            )}
          </div>
          {bird.color && (
            <p className="text-xs enhanced-text-secondary mt-1 truncate">
              {bird.color}
            </p>
          )}
        </div>

        {/* Seçim İkonu */}
        <ChevronRight className={`
          w-4 h-4 transition-transform duration-200 
          ${isSelected ? 'text-primary rotate-90' : 'text-muted-foreground group-hover:text-primary'}
        `} />
      </div>
    </div>
  );
};

export default BirdListItem;
