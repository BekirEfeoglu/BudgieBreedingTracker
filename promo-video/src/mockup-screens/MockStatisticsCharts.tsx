import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';

interface MockStatisticsChartsProps {
  frame: number;
  lang: Language;
}

export const MockStatisticsCharts: React.FC<MockStatisticsChartsProps> = ({ frame, lang }) => {
  const chartProgress = interpolate(frame, [20, 150], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  return (
    <div style={{
      width: PHONE.width, height: PHONE.height,
      background: colors.neutral50,
      padding: '54px 16px 64px', overflow: 'hidden',
    }}>
      <div style={{
        fontFamily, fontSize: 16, fontWeight: 700, color: colors.neutral900,
        marginBottom: 12, paddingTop: 4,
      }}>
        📊 {lang === 'tr' ? 'Istatistikler' : 'Statistics'}
      </div>

      {/* Gender Pie Chart */}
      <div style={{
        background: colors.white, borderRadius: 14, padding: 14,
        marginBottom: 10, border: `1px solid ${colors.neutral200}`,
      }}>
        <div style={{ fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral700, marginBottom: 8 }}>
          {lang === 'tr' ? 'Cinsiyet Dagilimi' : 'Gender Distribution'}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
          <svg width={80} height={80} viewBox="-1 -1 2 2" style={{ transform: 'rotate(-90deg)' }}>
            {/* Male slice (60%) */}
            <circle r="1" fill="transparent" stroke={colors.genderMale} strokeWidth="1"
              strokeDasharray={`${Math.PI * 2 * 0.6 * chartProgress} ${Math.PI * 2}`}
            />
            {/* Female slice (40%) */}
            <circle r="1" fill="transparent" stroke={colors.genderFemale} strokeWidth="1"
              strokeDasharray={`${Math.PI * 2 * 0.4 * chartProgress} ${Math.PI * 2}`}
              strokeDashoffset={`${-Math.PI * 2 * 0.6}`}
            />
          </svg>
          <div>
            {[
              { label: lang === 'tr' ? 'Erkek' : 'Male', pct: '60%', color: colors.genderMale },
              { label: lang === 'tr' ? 'Disi' : 'Female', pct: '40%', color: colors.genderFemale },
            ].map((item, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                <div style={{ width: 8, height: 8, borderRadius: 4, background: item.color }} />
                <span style={{ fontFamily, fontSize: 10, color: colors.neutral600 }}>{item.label}: {item.pct}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Breeding Success Bar Chart */}
      <div style={{
        background: colors.white, borderRadius: 14, padding: 14,
        marginBottom: 10, border: `1px solid ${colors.neutral200}`,
      }}>
        <div style={{ fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral700, marginBottom: 10 }}>
          {lang === 'tr' ? 'Ureme Basari Orani' : 'Breeding Success Rate'}
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 80 }}>
          {[
            { month: 'Oca', value: 0.7 },
            { month: 'Sub', value: 0.85 },
            { month: 'Mar', value: 0.6 },
            { month: 'Nis', value: 0.9 },
            { month: 'May', value: 0.75 },
            { month: 'Haz', value: 0.95 },
          ].map((bar, i) => {
            const barHeight = 70 * bar.value * chartProgress;
            const barColor = bar.value >= 0.8 ? colors.success : bar.value >= 0.6 ? colors.accent : colors.error;
            return (
              <div key={i} style={{ flex: 1, textAlign: 'center' }}>
                <div style={{
                  height: barHeight, background: barColor,
                  borderRadius: '4px 4px 0 0', marginBottom: 4,
                  minHeight: 2,
                }} />
                <div style={{ fontFamily, fontSize: 8, color: colors.neutral500 }}>{bar.month}</div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Monthly Trend Line */}
      <div style={{
        background: colors.white, borderRadius: 14, padding: 14,
        border: `1px solid ${colors.neutral200}`,
      }}>
        <div style={{ fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral700, marginBottom: 8 }}>
          {lang === 'tr' ? 'Aylik Yumurta Uretimi' : 'Monthly Egg Production'}
        </div>
        <svg width={PHONE.width - 60} height={60} viewBox={`0 0 ${PHONE.width - 60} 60`}>
          {/* Line chart */}
          <polyline
            fill="none" stroke={colors.primary} strokeWidth={2}
            strokeLinecap="round" strokeLinejoin="round"
            points={[
              [0, 45], [50, 35], [100, 40], [150, 20], [200, 25], [250, 10],
            ].map(([x, y]) => `${x},${y}`).join(' ')}
            strokeDasharray="400"
            strokeDashoffset={400 * (1 - chartProgress)}
          />
          {/* Area fill */}
          <polygon
            fill={`${colors.primary}10`}
            points={`0,60 0,45 50,35 100,40 150,20 200,25 250,10 ${PHONE.width - 60},60`}
            opacity={chartProgress}
          />
        </svg>
      </div>
    </div>
  );
};
