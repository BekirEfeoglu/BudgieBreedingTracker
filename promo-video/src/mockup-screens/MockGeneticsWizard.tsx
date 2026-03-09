import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';

interface MockGeneticsWizardProps {
  frame: number;
  lang: Language;
}

const mutations = ['Green', 'Blue', 'Lutino', 'Albino', 'Opaline', 'Cinnamon', 'Spangle', 'Violet'];
const punnettResults = [
  ['Green', 'Green/blue', 'Green', 'Green/blue'],
  ['Green/blue', 'Blue', 'Green/blue', 'Blue'],
  ['Green', 'Green/blue', 'Green', 'Green/blue'],
  ['Green/blue', 'Blue', 'Green/blue', 'Blue'],
];

export const MockGeneticsWizard: React.FC<MockGeneticsWizardProps> = ({ frame, lang }) => {
  // Wizard step: 0=parent selection, 1=Punnett square
  const step = frame < 120 ? 0 : 1;

  return (
    <div style={{
      width: PHONE.width, height: PHONE.height,
      background: colors.neutral50,
      padding: '54px 16px 64px', overflow: 'hidden',
    }}>
      <div style={{
        fontFamily, fontSize: 16, fontWeight: 700, color: colors.neutral900,
        marginBottom: 8, paddingTop: 4,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        🧬 {lang === 'tr' ? 'Genetik Hesaplayici' : 'Genetics Calculator'}
      </div>

      {/* Step indicator */}
      <div style={{
        display: 'flex', gap: 4, marginBottom: 14,
      }}>
        {[1, 2, 3].map(s => (
          <div key={s} style={{
            flex: 1, height: 3, borderRadius: 2,
            background: s <= step + 1 ? colors.primary : colors.neutral200,
          }} />
        ))}
      </div>

      {step === 0 ? (
        /* Step 1: Mutation Selection */
        <>
          <div style={{
            fontFamily, fontSize: 12, fontWeight: 600, color: colors.neutral700,
            marginBottom: 8,
          }}>
            {lang === 'tr' ? 'Baba Mutasyonlari' : 'Father Mutations'}
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 14 }}>
            {mutations.slice(0, 4).map((m, i) => {
              const delay = 15 + i * 8;
              const opacity = interpolate(frame, [delay, delay + 12], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
              const isSelected = i === 0;
              return (
                <div key={i} style={{
                  opacity,
                  padding: '6px 12px', borderRadius: 16,
                  background: isSelected ? colors.primary : colors.white,
                  color: isSelected ? 'white' : colors.neutral700,
                  border: isSelected ? 'none' : `1px solid ${colors.neutral200}`,
                  fontFamily, fontSize: 11, fontWeight: 500,
                }}>
                  {m}
                </div>
              );
            })}
          </div>

          <div style={{
            fontFamily, fontSize: 12, fontWeight: 600, color: colors.neutral700,
            marginBottom: 8,
          }}>
            {lang === 'tr' ? 'Anne Mutasyonlari' : 'Mother Mutations'}
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 14 }}>
            {mutations.slice(0, 4).map((m, i) => {
              const delay = 50 + i * 8;
              const opacity = interpolate(frame, [delay, delay + 12], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
              const isSelected = i === 1;
              return (
                <div key={i} style={{
                  opacity,
                  padding: '6px 12px', borderRadius: 16,
                  background: isSelected ? colors.genderFemale : colors.white,
                  color: isSelected ? 'white' : colors.neutral700,
                  border: isSelected ? 'none' : `1px solid ${colors.neutral200}`,
                  fontFamily, fontSize: 11, fontWeight: 500,
                }}>
                  {m}
                </div>
              );
            })}
          </div>

          {/* Calculate button */}
          <div style={{
            opacity: interpolate(frame, [80, 95], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }),
            background: `linear-gradient(135deg, ${colors.primary}, ${colors.primaryLight})`,
            borderRadius: 12, padding: '12px 0', textAlign: 'center',
            color: 'white', fontFamily, fontSize: 13, fontWeight: 600,
          }}>
            {lang === 'tr' ? 'Hesapla →' : 'Calculate →'}
          </div>
        </>
      ) : (
        /* Step 2: Punnett Square Results */
        <>
          <div style={{
            fontFamily, fontSize: 12, fontWeight: 600, color: colors.neutral700,
            marginBottom: 8,
          }}>
            {lang === 'tr' ? 'Punnett Karesi Sonuclari' : 'Punnett Square Results'}
          </div>

          {/* Punnett Grid */}
          <div style={{
            background: colors.white, borderRadius: 12, padding: 10,
            border: `1px solid ${colors.neutral200}`, marginBottom: 14,
          }}>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 4 }}>
              {punnettResults.flat().map((cell, i) => {
                const delay = (frame - 120) - i * 3;
                const opacity = interpolate(delay, [0, 10], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
                const isGreen = cell === 'Green';
                const isBlue = cell === 'Blue';
                const bg = isGreen ? `${colors.success}15` : isBlue ? `${colors.primary}15` : `${colors.accent}08`;
                return (
                  <div key={i} style={{
                    opacity,
                    padding: '8px 4px', borderRadius: 6,
                    background: bg, textAlign: 'center',
                    fontFamily, fontSize: 8, fontWeight: 500, color: colors.neutral700,
                    border: `1px solid ${colors.neutral100}`,
                  }}>
                    {cell}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Probability bars */}
          <div style={{ fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral700, marginBottom: 8 }}>
            {lang === 'tr' ? 'Olasiliklar' : 'Probabilities'}
          </div>
          {[
            { label: 'Green', pct: 50, color: colors.success },
            { label: 'Green/blue', pct: 25, color: colors.accent },
            { label: 'Blue', pct: 25, color: colors.primary },
          ].map((item, i) => {
            const barProgress = interpolate(frame - 150, [i * 10, 20 + i * 10], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
            return (
              <div key={i} style={{ marginBottom: 8 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
                  <span style={{ fontFamily, fontSize: 10, color: colors.neutral700 }}>{item.label}</span>
                  <span style={{ fontFamily, fontSize: 10, fontWeight: 600, color: item.color }}>{item.pct}%</span>
                </div>
                <div style={{
                  width: '100%', height: 6, background: colors.neutral200,
                  borderRadius: 3, overflow: 'hidden',
                }}>
                  <div style={{
                    width: `${item.pct * barProgress}%`, height: '100%',
                    background: item.color, borderRadius: 3,
                  }} />
                </div>
              </div>
            );
          })}
        </>
      )}
    </div>
  );
};
