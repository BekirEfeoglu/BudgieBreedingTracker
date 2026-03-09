import React from 'react';
import { interpolate } from 'remotion';
import { PHONE } from '../config/constants';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import type { Language } from '../i18n/types';

interface MockCalendarProps {
  frame: number;
  lang: Language;
}

const events: Record<number, { color: string; label: string; labelEn: string }[]> = {
  3: [{ color: colors.primary, label: 'Mum testi', labelEn: 'Candling' }],
  7: [{ color: colors.success, label: 'Yumurta kontrolu', labelEn: 'Egg check' }],
  12: [
    { color: colors.accent, label: 'Cevirme', labelEn: 'Turn eggs' },
    { color: colors.primary, label: 'Asi', labelEn: 'Vaccination' },
  ],
  15: [{ color: colors.error, label: 'Cikis bekleniyor', labelEn: 'Expected hatch' }],
  20: [{ color: colors.success, label: 'Tartim', labelEn: 'Weigh-in' }],
  25: [{ color: '#F97316', label: 'Halkalama', labelEn: 'Banding' }],
};

const dayNames = {
  tr: ['Pzt', 'Sal', 'Car', 'Per', 'Cum', 'Cmt', 'Paz'],
  en: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
};

export const MockCalendar: React.FC<MockCalendarProps> = ({ frame, lang }) => {
  const days = dayNames[lang];
  const selectedDay = Math.floor(interpolate(frame, [60, 200], [3, 15.99], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }));
  const detailOpacity = interpolate(frame, [80, 100], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  // Generate calendar grid (Feb 2026 starts on Sunday)
  const calendarDays: (number | null)[] = [];
  for (let i = 0; i < 6; i++) calendarDays.push(null); // padding for Sun start
  for (let i = 1; i <= 28; i++) calendarDays.push(i);

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
        📅 {lang === 'tr' ? 'Subat 2026' : 'February 2026'}
      </div>

      {/* Day headers */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2, marginBottom: 6 }}>
        {days.map((d, i) => (
          <div key={i} style={{
            fontFamily, fontSize: 9, fontWeight: 600, color: colors.neutral400,
            textAlign: 'center', padding: '4px 0',
          }}>
            {d}
          </div>
        ))}
      </div>

      {/* Calendar grid */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2,
        marginBottom: 14,
      }}>
        {calendarDays.map((day, i) => {
          if (day === null) return <div key={i} />;
          const dayEvents = events[day] || [];
          const isSelected = day === selectedDay;
          const isToday = day === 17;

          const cellDelay = 10 + (day / 28) * 40;
          const cellOpacity = interpolate(frame, [cellDelay, cellDelay + 10], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

          return (
            <div key={i} style={{
              opacity: cellOpacity,
              padding: '6px 2px 4px', textAlign: 'center',
              borderRadius: 8,
              background: isSelected ? colors.primary : isToday ? `${colors.primary}10` : 'transparent',
              border: isToday && !isSelected ? `1px solid ${colors.primary}40` : 'none',
              position: 'relative',
            }}>
              <div style={{
                fontFamily, fontSize: 11,
                fontWeight: isToday || isSelected ? 700 : 400,
                color: isSelected ? 'white' : isToday ? colors.primary : colors.neutral800,
              }}>
                {day}
              </div>
              {/* Event dots */}
              {dayEvents.length > 0 && (
                <div style={{ display: 'flex', justifyContent: 'center', gap: 2, marginTop: 2 }}>
                  {dayEvents.map((ev, j) => (
                    <div key={j} style={{
                      width: 4, height: 4, borderRadius: 2,
                      background: isSelected ? 'white' : ev.color,
                    }} />
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Selected day events */}
      <div style={{ opacity: detailOpacity }}>
        <div style={{
          fontFamily, fontSize: 11, fontWeight: 600, color: colors.neutral700,
          marginBottom: 8,
        }}>
          {lang === 'tr' ? `${selectedDay} Subat Etkinlikleri` : `February ${selectedDay} Events`}
        </div>
        {(events[selectedDay] || [{ color: colors.neutral400, label: 'Etkinlik yok', labelEn: 'No events' }])
          .map((ev, i) => (
            <div key={i} style={{
              background: colors.white, borderRadius: 10,
              padding: '10px 14px', marginBottom: 6,
              border: `1px solid ${colors.neutral200}`,
              borderLeft: `4px solid ${ev.color}`,
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <div style={{
                width: 8, height: 8, borderRadius: 4,
                background: ev.color,
              }} />
              <span style={{ fontFamily, fontSize: 11, color: colors.neutral800, fontWeight: 500 }}>
                {lang === 'tr' ? ev.label : ev.labelEn}
              </span>
            </div>
          ))}
      </div>
    </div>
  );
};
