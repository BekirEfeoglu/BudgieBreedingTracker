import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import { PhoneMockup } from '../components/PhoneMockup';
import { PhoneStatusBar } from '../components/PhoneStatusBar';
import { PhoneNavBar } from '../components/PhoneNavBar';
import { MockDashboard } from '../mockup-screens/MockDashboard';
import { FeatureTag } from '../components/FeatureTag';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import { WIDTH, HEIGHT } from '../config/constants';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface Scene02Props {
  lang: Language;
}

export const Scene02_Dashboard: React.FC<Scene02Props> = ({ lang }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = lang === 'tr' ? tr : en;

  // Phone slide in from left
  const phoneSpring = spring({ frame, fps, config: { damping: 15, stiffness: 80 } });
  const phoneX = interpolate(phoneSpring, [0, 1], [-400, 0]);
  const phoneOpacity = phoneSpring;

  // Section title
  const titleOpacity = interpolate(frame, [15, 35], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  return (
    <AbsoluteFill style={{ background: colors.neutral50 }}>
      {/* Section title at top */}
      <div style={{
        position: 'absolute', top: 60, left: 0, width: WIDTH, textAlign: 'center',
        opacity: titleOpacity,
      }}>
        <div style={{ fontFamily, fontSize: 18, fontWeight: 700, color: colors.primary, letterSpacing: 2, textTransform: 'uppercase' }}>
          {t.dashboard.title}
        </div>
      </div>

      {/* Phone mockup - centered */}
      <div style={{
        position: 'absolute',
        top: HEIGHT * 0.08,
        left: (WIDTH - 356) / 2,
        opacity: phoneOpacity,
        transform: `translateX(${phoneX}px)`,
      }}>
        <PhoneMockup scale={1.15}>
          <PhoneStatusBar />
          <MockDashboard frame={frame} lang={lang} />
          <PhoneNavBar activeTab="home" />
        </PhoneMockup>
      </div>

      {/* Feature tags at bottom */}
      <div style={{
        position: 'absolute', bottom: 80, left: 60, right: 60,
        display: 'flex', flexDirection: 'column', gap: 12,
      }}>
        <FeatureTag icon="home.svg" text={t.dashboard.realtimeOverview} startFrame={150} />
        <FeatureTag icon="statistics.svg" text={t.dashboard.statsAtGlance} startFrame={170} color={colors.accent} />
        <FeatureTag icon="breeding.svg" text={t.dashboard.quickActions} startFrame={190} color={colors.success} />
      </div>
    </AbsoluteFill>
  );
};
