import React, { memo } from 'react';
import { Bird, Chick } from '@/types';
import { format, differenceInDays } from 'date-fns';
import { tr } from 'date-fns/locale';
import { resolveAgeCategoryKey } from '@/utils/translationHelpers';
import { useLanguage } from '@/contexts/LanguageContext';

interface BirdNodeProps {
  bird: Bird | Chick;
  position: string;
  label?: string;
  isSelected?: boolean;
  onClick?: () => void;
  collapsed?: boolean;
  expandedView?: boolean;
}

const BirdNode = memo(({ bird, position, label, isSelected = false, onClick, collapsed = false, expandedView = false }: BirdNodeProps) => {
  const { t } = useLanguage();
  const getGenderIcon = (gender: string) => {
    switch (gender) {
      case 'male': return '♂️';
      case 'female': return '♀️';
      default: return '❓';
    }
  };

  const getGenderColor = (gender: string) => {
    switch (gender) {
      case 'male': return 'border-blue-500 bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/30 dark:to-blue-800/40';
      case 'female': return 'border-pink-500 bg-gradient-to-br from-pink-50 to-pink-100 dark:from-pink-900/30 dark:to-pink-800/40';
      default: return 'border-gray-500 bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900/30 dark:to-gray-800/40';
    }
  };

  const getAgeGroup = (bird: Bird | Chick) => {
    const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;
    if (!birthDate) return 'unknown';
    
    const age = differenceInDays(new Date(), new Date(birthDate));
    if (age <= 30) return 'baby';
    if (age <= 90) return 'young';
    if (age <= 365) return resolveAgeCategoryKey('adult', t);
    return 'senior';
  };

  const getAgeIcon = (ageGroup: string) => {
    switch (ageGroup) {
      case 'baby': return '🐣';
      case 'young': return '🐤';
      case 'adult': return '🐦';
      case 'senior': return '🦜';
      default: return '🐤';
    }
  };

  const isChick = 'hatchDate' in bird && bird.hatchDate;
  const ageGroup = getAgeGroup(bird);
  const birthDate = 'hatchDate' in bird ? bird.hatchDate : bird.birthDate;

  const getAccessibilityLabel = () => {
    const parts = [bird.name];
    if (bird.ringNumber) parts.push(bird.ringNumber);
    if (label) parts.push(label);
    if (isSelected) parts.push('seçili');
    return parts.join(', ');
  };

  const handleClick = () => {
    if (onClick) onClick();
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    }
  };

  if (collapsed) {
    return (
      <div 
        className="w-14 h-14 sm:w-16 sm:h-16 rounded-full border-2 border-dashed border-gray-400 bg-gray-100 dark:bg-gray-800 flex items-center justify-center cursor-pointer hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors mobile-touch-target-large"
        onClick={handleClick}
        onKeyPress={handleKeyPress}
        role="button"
        tabIndex={0}
        aria-label="Dalları göster"
      >
        <span className="text-gray-600 dark:text-gray-400 text-sm">...</span>
      </div>
    );
  }

  return (
    <div 
      className={`
        relative p-3 sm:p-2 rounded-xl border-2 shadow-lg transition-all duration-300 hover:shadow-xl hover:scale-105 cursor-pointer mobile-touch-target-large
        ${isSelected ? 'border-primary bg-primary/10 shadow-primary/25 scale-110' : getGenderColor(bird.gender)}
        ${expandedView 
          ? (position === 'center' ? 'w-40 sm:w-44 md:w-48' : 'w-32 sm:w-36 md:w-40')
          : (position === 'center' ? 'w-36 sm:w-40 md:w-44' : 'w-28 sm:w-32 md:w-36')
        }
        ${expandedView 
          ? 'min-h-[160px] sm:min-h-[170px] md:min-h-[180px]' 
          : 'min-h-[140px] sm:min-h-[150px] md:min-h-[160px]'
        }
      `}
      role="button"
      tabIndex={0}
      aria-label={getAccessibilityLabel()}
      aria-pressed={isSelected}
      onClick={handleClick}
      onKeyPress={handleKeyPress}
    >
      {/* Fotoğraf veya İkon */}
      <div className="flex justify-center mb-2">
        {bird.photo ? (
          <img 
            src={bird.photo} 
            alt={bird.name}
            className="w-10 h-10 sm:w-12 sm:h-12 rounded-full object-cover border-2 border-white shadow-sm"
          />
        ) : (
          <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-white dark:bg-gray-800 border-2 border-gray-200 dark:border-gray-600 flex items-center justify-center text-lg sm:text-xl">
            {getAgeIcon(ageGroup)}
          </div>
        )}
      </div>

      {/* İçerik Alanı */}
      <div className="flex flex-col items-center justify-center space-y-1.5 sm:space-y-1 text-center">
        {/* İsim */}
        <div className="text-sm sm:text-sm font-bold enhanced-text-primary w-full px-1 leading-tight">
          <div className="truncate" title={bird.name}>
            {bird.name}
          </div>
        </div>
        
        {/* Cinsiyet ve Renk */}
        <div className="flex items-center justify-center gap-1.5 sm:gap-1">
          <span className="text-sm sm:text-xs">{getGenderIcon(bird.gender)}</span>
          {bird.color && (
            <div 
              className="w-3 h-3 sm:w-3 sm:h-3 rounded-full border border-gray-300 dark:border-gray-600"
              style={{ backgroundColor: bird.color }}
              title={bird.color}
            />
          )}
        </div>

        {/* Halka Numarası */}
        {bird.ringNumber && (
          <div className="text-xs sm:text-xs enhanced-text-secondary bg-white/60 dark:bg-gray-800/60 px-1.5 py-0.5 rounded w-full leading-tight">
            <div className="truncate" title={bird.ringNumber}>
              {bird.ringNumber}
            </div>
          </div>
        )}

        {/* Doğum Tarihi */}
        {birthDate && (
          <div className="text-xs enhanced-text-secondary w-full leading-tight">
            <div className="truncate" title={format(new Date(birthDate), 'dd.MM.yyyy', { locale: tr })}>
              {format(new Date(birthDate), 'dd.MM.yyyy', { locale: tr })}
            </div>
          </div>
        )}

        {/* Etiket */}
        {label && (
          <div className="text-xs font-medium text-primary bg-primary/10 px-1.5 py-0.5 rounded-full w-full leading-tight">
            <div className="truncate" title={label}>
              {label}
            </div>
          </div>
        )}
      </div>

      {/* Seçili göstergesi */}
      {isSelected && (
        <div className="absolute -top-1 -right-1 w-5 h-5 sm:w-4 sm:h-4 bg-primary rounded-full border-2 border-white shadow-md flex items-center justify-center">
          <span className="text-white text-xs">✓</span>
        </div>
      )}
    </div>
  );
});

BirdNode.displayName = 'BirdNode';

export default BirdNode;
