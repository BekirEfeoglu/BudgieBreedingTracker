import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';

interface MockBreedingDetailProps {
  frame: number;
  lang: Language;
}

export const MockBreedingDetail: React.FC<MockBreedingDetailProps> = ({ frame, lang }) => {
  const progressDay = Math.round(interpolate(frame, [20, 200], [0, 14], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }));
  const progressPercent = (progressDay / 18) * 100;

  const milestones = [
    { day: 0, label: lang === 'tr' ? 'Baslangic' : 'Start', done: progressDay >= 0 },
    { day: 7, label: lang === 'tr' ? 'Mum Testi' : 'Candling', done: progressDay >= 7 },
    { day: 14, label: lang === 'tr' ? '2. Kontrol' : '2nd Check', done: progressDay >= 14 },
    { day: 18, label: lang === 'tr' ? 'Cikis!' : 'Hatch!', done: false },
  ];

  return (
    <div style={{
      width: PHONE.width,
      height: PHONE.height,
      background: colors.neutral50,
      padding: '54px 16px 64px',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{
        fontFamily, fontSize: 16, fontWeight: 700, color: colors.neutral900,
        marginBottom: 16, paddingTop: 4,
      }}>
        {lang === 'tr' ? '← Ureme Detayi' : '← Breeding Detail'}
      </div>

      {/* Pair Card */}
      <div style={{
        background: `linear-gradient(135deg, ${colors.primary}08, ${colors.primaryLight}05)`,
        borderRadius: 14, padding: 16, marginBottom: 16,
        border: `1px solid ${colors.primary}15`,
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 24, marginBottom: 12 }}>
          {/* Male */}
          <div style={{ textAlign: 'center' }}>
            <div style={{
              width: 50, height: 50, borderRadius: 25,
              background: `${colors.genderMale}15`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 24, margin: '0 auto 6px',
            }}>♂</div>
            <div style={{ fontFamily, fontSize: 13, fontWeight: 600, color: colors.genderMale }}>Mavis</div>
            <div style={{ fontFamily, fontSize: 9, color: colors.neutral500 }}>TR-2024-001</div>
          </div>

          <div style={{
            display: 'flex', alignItems: 'center',
            fontSize: 22, color: colors.error,
          }}>❤️</div>

          {/* Female */}
          <div style={{ textAlign: 'center' }}>
            <div style={{
              width: 50, height: 50, borderRadius: 25,
              background: `${colors.genderFemale}15`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 24, margin: '0 auto 6px',
            }}>♀</div>
            <div style={{ fontFamily, fontSize: 13, fontWeight: 600, color: colors.genderFemale }}>Pamuk</div>
            <div style={{ fontFamily, fontSize: 9, color: colors.neutral500 }}>TR-2024-002</div>
          </div>
        </div>

        {/* Day counter */}
        <div style={{ textAlign: 'center', marginBottom: 10 }}>
          <span style={{
            fontFamily, fontSize: 32, fontWeight: 800, color: colors.primary,
          }}>{progressDay}</span>
          <span style={{ fontFamily, fontSize: 14, color: colors.neutral500 }}> / 18 {lang === 'tr' ? 'Gun' : 'Days'}</span>
        </div>

        {/* Progress bar */}
        <div style={{
          width: '100%', height: 8, background: colors.neutral200,
          borderRadius: 4, overflow: 'hidden',
        }}>
          <div style={{
            width: `${progressPercent}%`, height: '100%',
            background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
            borderRadius: 4,
            transition: 'width 0.1s',
          }} />
        </div>
      </div>

      {/* Milestones Timeline */}
      <div style={{
        fontFamily, fontSize: 12, fontWeight: 600, color: colors.neutral700,
        marginBottom: 10,
      }}>
        {lang === 'tr' ? 'Kilometre Taslari' : 'Milestones'}
      </div>

      {milestones.map((ms, i) => {
        const delay = 60 + i * 20;
        const opacity = interpolate(frame, [delay, delay + 15], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
        return (
          <div key={i} style={{
            opacity,
            display: 'flex', alignItems: 'center', gap: 12,
            marginBottom: 10, paddingLeft: 8,
          }}>
            {/* Dot */}
            <div style={{
              width: 14, height: 14, borderRadius: 7,
              background: ms.done ? colors.success : colors.neutral300,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 8, color: 'white',
            }}>
              {ms.done ? '✓' : ''}
            </div>
            {/* Line connector */}
            {i < milestones.length - 1 && (
              <div style={{
                position: 'absolute',
                left: 30, top: 14, width: 2, height: 20,
                background: ms.done ? colors.success : colors.neutral300,
              }} />
            )}
            <div>
              <div style={{ fontFamily, fontSize: 12, fontWeight: 600, color: ms.done ? colors.neutral800 : colors.neutral400 }}>
                {lang === 'tr' ? `${ms.day}. Gun` : `Day ${ms.day}`} - {ms.label}
              </div>
            </div>
          </div>
        );
      })}

      {/* Info cards */}
      <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
        <div style={{
          flex: 1, background: colors.white, borderRadius: 10, padding: '10px 12px',
          border: `1px solid ${colors.neutral200}`, textAlign: 'center',
        }}>
          <div style={{ fontSize: 18 }}>🌡️</div>
          <div style={{ fontFamily, fontSize: 16, fontWeight: 700, color: colors.neutral800 }}>37.5°C</div>
          <div style={{ fontFamily, fontSize: 8, color: colors.neutral500 }}>
            {lang === 'tr' ? 'Sicaklik' : 'Temperature'}
          </div>
        </div>
        <div style={{
          flex: 1, background: colors.white, borderRadius: 10, padding: '10px 12px',
          border: `1px solid ${colors.neutral200}`, textAlign: 'center',
        }}>
          <div style={{ fontSize: 18 }}>💧</div>
          <div style={{ fontFamily, fontSize: 16, fontWeight: 700, color: colors.neutral800 }}>60%</div>
          <div style={{ fontFamily, fontSize: 8, color: colors.neutral500 }}>
            {lang === 'tr' ? 'Nem' : 'Humidity'}
          </div>
        </div>
        <div style={{
          flex: 1, background: colors.white, borderRadius: 10, padding: '10px 12px',
          border: `1px solid ${colors.neutral200}`, textAlign: 'center',
        }}>
          <div style={{ fontSize: 18 }}>🥚</div>
          <div style={{ fontFamily, fontSize: 16, fontWeight: 700, color: colors.neutral800 }}>4</div>
          <div style={{ fontFamily, fontSize: 8, color: colors.neutral500 }}>
            {lang === 'tr' ? 'Yumurta' : 'Eggs'}
          </div>
        </div>
      </div>
    </div>
  );
};
