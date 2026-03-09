import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface MockDashboardProps {
  frame: number;
  lang: Language;
}

const StatCard: React.FC<{
  label: string;
  value: number;
  color: string;
  emoji: string;
  frame: number;
  index: number;
}> = ({ label, value, color, emoji, frame, index }) => {
  const delay = 30 + index * 15;
  const opacity = interpolate(frame, [delay, delay + 20], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const y = interpolate(frame, [delay, delay + 20], [15, 0], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const countUp = Math.round(interpolate(frame, [delay, delay + 40], [0, value], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }));

  return (
    <div style={{
      flex: '1 1 45%',
      background: `${color}10`,
      borderRadius: 12,
      padding: '12px 10px',
      opacity,
      transform: `translateY(${y}px)`,
      border: `1px solid ${color}25`,
    }}>
      <div style={{ fontSize: 22, marginBottom: 4 }}>{emoji}</div>
      <div style={{ fontFamily, fontSize: 22, fontWeight: 700, color }}>{countUp}</div>
      <div style={{ fontFamily, fontSize: 9, color: colors.neutral500, marginTop: 2 }}>{label}</div>
    </div>
  );
};

export const MockDashboard: React.FC<MockDashboardProps> = ({ frame, lang }) => {
  const t = lang === 'tr' ? tr : en;

  const stats = [
    { label: t.dashboard.totalBirds, value: 24, color: colors.primary, emoji: '🐦' },
    { label: t.dashboard.activeBreedings, value: 3, color: colors.accent, emoji: '💕' },
    { label: t.dashboard.totalChicks, value: 8, color: colors.success, emoji: '🐤' },
    { label: t.dashboard.incubatingEggs, value: 5, color: '#F97316', emoji: '🥚' },
  ];

  const greetingOpacity = interpolate(frame, [10, 30], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const quickActionsOpacity = interpolate(frame, [100, 120], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const breedingOpacity = interpolate(frame, [130, 150], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

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
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 12, paddingTop: 4,
      }}>
        <div style={{ fontFamily, fontSize: 16, fontWeight: 800 }}>
          <span style={{ color: colors.primary }}>Budgie</span>
          <span style={{ color: colors.accent }}>Breeding</span>
          <span style={{ color: colors.primary }}>Tracker</span>
        </div>
        <div style={{
          width: 30, height: 30, borderRadius: 15,
          background: `linear-gradient(135deg, ${colors.primary}, ${colors.primaryLight})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'white', fontFamily, fontSize: 13, fontWeight: 700,
        }}>A</div>
      </div>

      {/* Greeting */}
      <div style={{
        opacity: greetingOpacity,
        background: `linear-gradient(135deg, ${colors.primary}12, ${colors.primaryLight}08)`,
        borderRadius: 12, padding: '12px 14px', marginBottom: 14,
        border: `1px solid ${colors.primary}15`,
      }}>
        <div style={{ fontFamily, fontSize: 14, fontWeight: 600, color: colors.neutral800 }}>
          {t.dashboard.greeting} 👋
        </div>
        <div style={{ fontFamily, fontSize: 10, color: colors.neutral500, marginTop: 2 }}>
          {lang === 'tr' ? '3 aktif ureme, 5 yumurta kuluckada' : '3 active breedings, 5 eggs incubating'}
        </div>
      </div>

      {/* Stats Grid */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 14 }}>
        {stats.map((stat, i) => (
          <StatCard key={i} {...stat} frame={frame} index={i} />
        ))}
      </div>

      {/* Quick Actions */}
      <div style={{ opacity: quickActionsOpacity, marginBottom: 14 }}>
        <div style={{ fontFamily, fontSize: 12, fontWeight: 600, color: colors.neutral700, marginBottom: 8 }}>
          {lang === 'tr' ? 'Hizli Erisim' : 'Quick Actions'}
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {['🐦 Kus Ekle', '💕 Cift Olustur', '🥚 Yumurta'].map((action, i) => (
            <div key={i} style={{
              flex: 1, background: colors.white, borderRadius: 10,
              padding: '10px 6px', textAlign: 'center',
              border: `1px solid ${colors.neutral200}`,
              fontFamily, fontSize: 9, color: colors.neutral700, fontWeight: 500,
            }}>
              {action}
            </div>
          ))}
        </div>
      </div>

      {/* Active Breedings */}
      <div style={{ opacity: breedingOpacity }}>
        <div style={{ fontFamily, fontSize: 12, fontWeight: 600, color: colors.neutral700, marginBottom: 8 }}>
          {lang === 'tr' ? 'Aktif Uremeler' : 'Active Breedings'}
        </div>
        {[
          { male: 'Mavis', female: 'Pamuk', day: 12, total: 18 },
          { male: 'Zeus', female: 'Hera', day: 5, total: 18 },
        ].map((pair, i) => (
          <div key={i} style={{
            background: colors.white, borderRadius: 10,
            padding: '10px 12px', marginBottom: 6,
            border: `1px solid ${colors.neutral200}`,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div>
              <span style={{ color: colors.genderMale, fontSize: 14 }}>♂</span>
              <span style={{ color: colors.genderFemale, fontSize: 14, marginLeft: 4 }}>♀</span>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral800 }}>
                {pair.male} & {pair.female}
              </div>
              <div style={{
                width: '100%', height: 4, background: colors.neutral200,
                borderRadius: 2, marginTop: 4, overflow: 'hidden',
              }}>
                <div style={{
                  width: `${(pair.day / pair.total) * 100}%`, height: '100%',
                  background: `linear-gradient(90deg, ${colors.primary}, ${colors.primaryLight})`,
                  borderRadius: 2,
                }} />
              </div>
            </div>
            <div style={{ fontFamily, fontSize: 10, color: colors.neutral500, fontWeight: 500 }}>
              {pair.day}/{pair.total}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
