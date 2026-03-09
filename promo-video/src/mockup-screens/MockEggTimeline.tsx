import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';

interface MockEggTimelineProps {
  frame: number;
  lang: Language;
}

const eggStatuses = [
  { status: 'fertile', color: colors.success, emoji: '🥚' },
  { status: 'fertile', color: colors.success, emoji: '🥚' },
  { status: 'incubating', color: '#F97316', emoji: '🔥' },
  { status: 'hatched', color: colors.primary, emoji: '🐣' },
  { status: 'infertile', color: colors.neutral400, emoji: '⊘' },
];

export const MockEggTimeline: React.FC<MockEggTimelineProps> = ({ frame, lang }) => {
  const statusLabels = lang === 'tr'
    ? { fertile: 'Dolu', incubating: 'Kulucka', hatched: 'Cikti', infertile: 'Bos' }
    : { fertile: 'Fertile', incubating: 'Incubating', hatched: 'Hatched', infertile: 'Infertile' };

  return (
    <div style={{
      width: PHONE.width, height: PHONE.height,
      background: colors.neutral50,
      padding: '54px 16px 64px', overflow: 'hidden',
    }}>
      <div style={{
        fontFamily, fontSize: 16, fontWeight: 700, color: colors.neutral900,
        marginBottom: 14, paddingTop: 4,
      }}>
        {lang === 'tr' ? '🥚 Yumurta Yonetimi' : '🥚 Egg Management'}
      </div>

      {/* Egg status summary */}
      <div style={{
        display: 'flex', gap: 6, marginBottom: 14,
      }}>
        {[
          { label: lang === 'tr' ? 'Toplam' : 'Total', value: 5, color: colors.neutral700 },
          { label: lang === 'tr' ? 'Dolu' : 'Fertile', value: 3, color: colors.success },
          { label: lang === 'tr' ? 'Cikti' : 'Hatched', value: 1, color: colors.primary },
        ].map((item, i) => {
          const opacity = interpolate(frame, [10 + i * 10, 25 + i * 10], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
          return (
            <div key={i} style={{
              opacity, flex: 1, background: `${item.color}10`,
              borderRadius: 10, padding: '8px 6px', textAlign: 'center',
              border: `1px solid ${item.color}20`,
            }}>
              <div style={{ fontFamily, fontSize: 18, fontWeight: 700, color: item.color }}>{item.value}</div>
              <div style={{ fontFamily, fontSize: 8, color: colors.neutral500 }}>{item.label}</div>
            </div>
          );
        })}
      </div>

      {/* Egg cards */}
      {eggStatuses.map((egg, i) => {
        const delay = 30 + i * 15;
        const opacity = interpolate(frame, [delay, delay + 18], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
        const x = interpolate(frame, [delay, delay + 18], [30, 0], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
        const statusColor = egg.color;
        const label = statusLabels[egg.status as keyof typeof statusLabels];

        // Lifecycle animation: status changes on 3rd egg
        const isAnimating = i === 2 && frame > 120;
        const animPhase = isAnimating
          ? Math.floor(interpolate(frame, [120, 220], [0, 2.99], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }))
          : -1;
        const phases = ['fertile', 'incubating', 'hatched'];
        const phaseEmojis = ['🥚', '🔥', '🐣'];
        const phaseColors = [colors.success, '#F97316', colors.primary];

        const displayEmoji = isAnimating ? phaseEmojis[animPhase] || egg.emoji : egg.emoji;
        const displayColor = isAnimating ? phaseColors[animPhase] || statusColor : statusColor;
        const displayLabel = isAnimating
          ? statusLabels[phases[animPhase] as keyof typeof statusLabels] || label
          : label;

        return (
          <div key={i} style={{
            opacity, transform: `translateX(${x}px)`,
            background: colors.white, borderRadius: 12,
            padding: '10px 14px', marginBottom: 6,
            display: 'flex', alignItems: 'center', gap: 12,
            border: `1px solid ${colors.neutral200}`,
            borderLeft: `4px solid ${displayColor}`,
          }}>
            <div style={{ fontSize: 22 }}>{displayEmoji}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily, fontSize: 12, fontWeight: 600, color: colors.neutral800 }}>
                {lang === 'tr' ? `Yumurta #${i + 1}` : `Egg #${i + 1}`}
              </div>
              <div style={{ fontFamily, fontSize: 9, color: colors.neutral500 }}>
                {lang === 'tr' ? `Yumurtlama: ${15 + i} Ocak` : `Laid: Jan ${15 + i}`}
              </div>
            </div>
            <div style={{
              padding: '3px 10px', borderRadius: 10,
              background: `${displayColor}15`, color: displayColor,
              fontFamily, fontSize: 9, fontWeight: 600,
            }}>
              {displayLabel}
            </div>
          </div>
        );
      })}

      {/* Incubation info */}
      <div style={{
        marginTop: 14, background: `${colors.accent}08`,
        borderRadius: 12, padding: '10px 14px',
        border: `1px solid ${colors.accent}20`,
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <span style={{ fontSize: 16 }}>⏱️</span>
        <div>
          <div style={{ fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral800 }}>
            {lang === 'tr' ? 'Tahmini cikis: 2 Subat' : 'Expected hatch: Feb 2'}
          </div>
          <div style={{ fontFamily, fontSize: 9, color: colors.neutral500 }}>
            {lang === 'tr' ? '4 gun kaldi' : '4 days remaining'}
          </div>
        </div>
      </div>
    </div>
  );
};
