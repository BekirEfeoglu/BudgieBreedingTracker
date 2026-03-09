import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';

interface MockChickGrowthProps {
  frame: number;
  lang: Language;
}

const growthData = [
  { day: 1, weight: 2 },
  { day: 5, weight: 8 },
  { day: 10, weight: 16 },
  { day: 15, weight: 24 },
  { day: 20, weight: 30 },
  { day: 25, weight: 34 },
  { day: 30, weight: 36 },
];

const stages = [
  { name: 'Newborn', nameTr: 'Yeni Dogan', color: colors.stageNewborn, emoji: '🐣' },
  { name: 'Nestling', nameTr: 'Yuvadaki', color: colors.stageNestling, emoji: '🐥' },
  { name: 'Fledgling', nameTr: 'Tuylenme', color: colors.stageFledgling, emoji: '🐦' },
  { name: 'Juvenile', nameTr: 'Genc', color: colors.stageJuvenile, emoji: '🦜' },
];

export const MockChickGrowth: React.FC<MockChickGrowthProps> = ({ frame, lang }) => {
  // Chart draw progress
  const chartProgress = interpolate(frame, [30, 180], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  // Stage animation
  const activeStage = Math.floor(interpolate(frame, [50, 250], [0, 3.99], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }));

  const chartW = PHONE.width - 60;
  const chartH = 140;

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
        {lang === 'tr' ? '🐤 Yavru Detayi' : '🐤 Chick Detail'}
      </div>

      {/* Chick info card */}
      <div style={{
        background: colors.white, borderRadius: 14, padding: 14,
        marginBottom: 14, border: `1px solid ${colors.neutral200}`,
        display: 'flex', alignItems: 'center', gap: 14,
      }}>
        <div style={{
          width: 48, height: 48, borderRadius: 24,
          background: `${colors.stageNestling}15`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 26,
        }}>🐥</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily, fontSize: 14, fontWeight: 600, color: colors.neutral900 }}>
            {lang === 'tr' ? 'Yavru #1' : 'Chick #1'}
          </div>
          <div style={{ fontFamily, fontSize: 10, color: colors.neutral500 }}>
            {lang === 'tr' ? 'Mavis & Pamuk • 15 gunluk' : 'Mavis & Pamuk • 15 days old'}
          </div>
        </div>
        <div style={{
          padding: '4px 10px', borderRadius: 10,
          background: `${colors.success}15`, color: colors.success,
          fontFamily, fontSize: 9, fontWeight: 600,
        }}>
          {lang === 'tr' ? 'Saglikli' : 'Healthy'}
        </div>
      </div>

      {/* Development stages */}
      <div style={{
        fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral700,
        marginBottom: 8,
      }}>
        {lang === 'tr' ? 'Gelisim Asamalari' : 'Development Stages'}
      </div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
        {stages.map((stage, i) => (
          <div key={i} style={{
            flex: 1, textAlign: 'center', padding: '8px 4px',
            borderRadius: 10,
            background: i <= activeStage ? `${stage.color}15` : colors.neutral100,
            border: i === activeStage ? `2px solid ${stage.color}` : `1px solid ${colors.neutral200}`,
            opacity: i <= activeStage ? 1 : 0.5,
            transform: i === activeStage ? 'scale(1.05)' : 'scale(1)',
          }}>
            <div style={{ fontSize: 16, marginBottom: 2 }}>{stage.emoji}</div>
            <div style={{ fontFamily, fontSize: 8, fontWeight: 600, color: stage.color }}>
              {lang === 'tr' ? stage.nameTr : stage.name}
            </div>
          </div>
        ))}
      </div>

      {/* Growth Chart */}
      <div style={{
        fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral700,
        marginBottom: 8,
      }}>
        {lang === 'tr' ? 'Buyume Grafigi (gram)' : 'Growth Chart (grams)'}
      </div>
      <div style={{
        background: colors.white, borderRadius: 12, padding: '14px 10px',
        border: `1px solid ${colors.neutral200}`,
      }}>
        <svg width={chartW} height={chartH} viewBox={`0 0 ${chartW} ${chartH}`}>
          {/* Grid lines */}
          {[0, 1, 2, 3].map(i => (
            <line key={i}
              x1={0} y1={chartH - (i * chartH / 3)}
              x2={chartW} y2={chartH - (i * chartH / 3)}
              stroke={colors.neutral200} strokeWidth={0.5}
            />
          ))}

          {/* Data line */}
          <polyline
            fill="none"
            stroke={colors.primary}
            strokeWidth={2.5}
            strokeLinecap="round"
            strokeLinejoin="round"
            points={growthData
              .map((d, i) => {
                const x = (i / (growthData.length - 1)) * chartW;
                const y = chartH - (d.weight / 40) * chartH;
                return `${x},${y}`;
              })
              .join(' ')}
            strokeDasharray={chartW * 2}
            strokeDashoffset={chartW * 2 * (1 - chartProgress)}
          />

          {/* Data points */}
          {growthData.map((d, i) => {
            const pointProgress = interpolate(chartProgress, [i / growthData.length, (i + 0.5) / growthData.length], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
            const x = (i / (growthData.length - 1)) * chartW;
            const y = chartH - (d.weight / 40) * chartH;
            return (
              <circle key={i}
                cx={x} cy={y} r={3.5 * pointProgress}
                fill={colors.primary}
                opacity={pointProgress}
              />
            );
          })}
        </svg>
      </div>

      {/* Latest measurement */}
      <div style={{
        marginTop: 12, background: `${colors.info}08`,
        borderRadius: 10, padding: '10px 14px',
        border: `1px solid ${colors.info}20`,
        display: 'flex', justifyContent: 'space-around',
      }}>
        {[
          { label: lang === 'tr' ? 'Agirlik' : 'Weight', value: '24g', emoji: '⚖️' },
          { label: lang === 'tr' ? 'Kanat' : 'Wing', value: '4.2cm', emoji: '🪶' },
          { label: lang === 'tr' ? 'Kuyruk' : 'Tail', value: '1.8cm', emoji: '📏' },
        ].map((m, i) => (
          <div key={i} style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 14, marginBottom: 2 }}>{m.emoji}</div>
            <div style={{ fontFamily, fontSize: 13, fontWeight: 700, color: colors.neutral800 }}>{m.value}</div>
            <div style={{ fontFamily, fontSize: 8, color: colors.neutral500 }}>{m.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
};
