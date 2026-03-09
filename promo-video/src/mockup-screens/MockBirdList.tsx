import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';

interface MockBirdListProps {
  frame: number;
  lang: Language;
}

const birds = [
  { name: 'Mavis', ring: 'TR-2024-001', gender: 'male' as const, color: '💚', mutation: 'Yesil', age: '1y 3m' },
  { name: 'Pamuk', ring: 'TR-2024-002', gender: 'female' as const, color: '💛', mutation: 'Lutino', age: '1y 1m' },
  { name: 'Zeus', ring: 'TR-2024-003', gender: 'male' as const, color: '💙', mutation: 'Mavi', age: '2y' },
  { name: 'Boncuk', ring: 'TR-2024-004', gender: 'female' as const, color: '🤍', mutation: 'Albino', age: '8m' },
];

export const MockBirdList: React.FC<MockBirdListProps> = ({ frame, lang }) => {
  // Filter bar animation
  const filterOpacity = interpolate(frame, [10, 25], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  // Active filter slide
  const activeFilter = Math.floor(interpolate(frame, [120, 200], [0, 2.99], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }));
  const filters = lang === 'tr'
    ? ['Tumu', 'Erkek', 'Disi', 'Canli']
    : ['All', 'Male', 'Female', 'Alive'];

  return (
    <div style={{
      width: PHONE.width,
      height: PHONE.height,
      background: colors.neutral50,
      padding: '54px 16px 64px',
      overflow: 'hidden',
    }}>
      {/* App Bar */}
      <div style={{
        fontFamily, fontSize: 18, fontWeight: 700, color: colors.neutral900,
        marginBottom: 12, paddingTop: 4,
      }}>
        {lang === 'tr' ? '🐦 Kuslarim' : '🐦 My Birds'}
      </div>

      {/* Search Bar */}
      <div style={{
        opacity: filterOpacity,
        background: colors.white, borderRadius: 10, padding: '10px 14px',
        border: `1px solid ${colors.neutral200}`, marginBottom: 10,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <span style={{ fontSize: 14, opacity: 0.4 }}>🔍</span>
        <span style={{ fontFamily, fontSize: 12, color: colors.neutral400 }}>
          {lang === 'tr' ? 'Kus ara...' : 'Search birds...'}
        </span>
      </div>

      {/* Filter Chips */}
      <div style={{ opacity: filterOpacity, display: 'flex', gap: 6, marginBottom: 12 }}>
        {filters.map((f, i) => (
          <div key={i} style={{
            padding: '6px 14px', borderRadius: 20,
            background: i === activeFilter ? colors.primary : colors.white,
            color: i === activeFilter ? 'white' : colors.neutral600,
            fontFamily, fontSize: 11, fontWeight: 500,
            border: i === activeFilter ? 'none' : `1px solid ${colors.neutral200}`,
            transition: 'all 0.3s',
          }}>
            {f}
          </div>
        ))}
      </div>

      {/* Bird Cards */}
      {birds.map((bird, i) => {
        const delay = 20 + i * 12;
        const opacity = interpolate(frame, [delay, delay + 20], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
        const y = interpolate(frame, [delay, delay + 20], [20, 0], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
        const genderColor = bird.gender === 'male' ? colors.genderMale : colors.genderFemale;
        const genderSymbol = bird.gender === 'male' ? '♂' : '♀';

        // Highlight effect on 2nd card
        const isHighlighted = i === 1 && frame > 80 && frame < 130;
        const highlightScale = isHighlighted
          ? interpolate(frame, [80, 90, 120, 130], [1, 1.02, 1.02, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' })
          : 1;

        return (
          <div key={i} style={{
            opacity,
            transform: `translateY(${y}px) scale(${highlightScale})`,
            background: colors.white,
            borderRadius: 12,
            padding: '12px 14px',
            marginBottom: 8,
            display: 'flex', alignItems: 'center', gap: 12,
            border: isHighlighted ? `2px solid ${colors.primary}` : `1px solid ${colors.neutral200}`,
            boxShadow: isHighlighted ? `0 4px 16px ${colors.primary}20` : 'none',
          }}>
            {/* Avatar */}
            <div style={{
              width: 40, height: 40, borderRadius: 20,
              background: `${genderColor}15`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 20,
            }}>
              {bird.color}
            </div>

            {/* Info */}
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ fontFamily, fontSize: 13, fontWeight: 600, color: colors.neutral900 }}>
                  {bird.name}
                </span>
                <span style={{ color: genderColor, fontSize: 14, fontWeight: 700 }}>{genderSymbol}</span>
              </div>
              <div style={{ fontFamily, fontSize: 9, color: colors.neutral500, marginTop: 2 }}>
                {bird.ring} · {bird.mutation} · {bird.age}
              </div>
            </div>

            {/* Status badge */}
            <div style={{
              padding: '3px 8px', borderRadius: 10,
              background: `${colors.success}15`, color: colors.success,
              fontFamily, fontSize: 9, fontWeight: 600,
            }}>
              {lang === 'tr' ? 'Canli' : 'Alive'}
            </div>
          </div>
        );
      })}
    </div>
  );
};
