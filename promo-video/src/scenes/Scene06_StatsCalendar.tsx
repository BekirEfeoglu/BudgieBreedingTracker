import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import { PhoneMockup } from '../components/PhoneMockup';
import { PhoneStatusBar } from '../components/PhoneStatusBar';
import { PhoneNavBar } from '../components/PhoneNavBar';
import { MockStatisticsCharts } from '../mockup-screens/MockStatisticsCharts';
import { MockCalendar } from '../mockup-screens/MockCalendar';
import { FeatureTag } from '../components/FeatureTag';
import { PremiumBadge } from '../components/PremiumBadge';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import { WIDTH, HEIGHT } from '../config/constants';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface Scene06Props {
  lang: Language;
}

export const Scene06_StatsCalendar: React.FC<Scene06Props> = ({ lang }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = lang === 'tr' ? tr : en;

  const phase = frame < 150 ? 0 : 1;
  const phaseFrame = frame < 150 ? frame : frame - 150;

  const phoneSpring = spring({ frame, fps, config: { damping: 15, stiffness: 80 } });

  const transitionOpacity = (targetPhase: number) => {
    if (phase === targetPhase) {
      return interpolate(phaseFrame, [0, 15], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
    }
    if (phase > targetPhase) {
      return interpolate(frame, [150, 165], [1, 0], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
    }
    return 0;
  };

  return (
    <AbsoluteFill style={{ background: colors.neutral50 }}>
      {/* Title */}
      <div style={{
        position: 'absolute', top: 50, left: 0, width: WIDTH,
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
      }}>
        <div style={{ fontFamily, fontSize: 18, fontWeight: 700, color: colors.primary, letterSpacing: 2, textTransform: 'uppercase' }}>
          {t.stats.title}
        </div>
        {phase === 0 && <PremiumBadge startFrame={15} size="small" />}
      </div>

      {/* Phone */}
      <div style={{
        position: 'absolute',
        top: HEIGHT * 0.08,
        left: (WIDTH - 356) / 2,
        opacity: phoneSpring,
      }}>
        <PhoneMockup scale={1.15}>
          <PhoneStatusBar />
          <div style={{ position: 'relative', width: '100%', height: '100%' }}>
            <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', opacity: transitionOpacity(0) }}>
              <MockStatisticsCharts frame={phaseFrame} lang={lang} />
            </div>
            <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', opacity: transitionOpacity(1) }}>
              <MockCalendar frame={phaseFrame} lang={lang} />
            </div>
          </div>
          <PhoneNavBar activeTab={phase === 0 ? 'more' : 'calendar'} />
        </PhoneMockup>
      </div>

      {/* Feature tags */}
      <div style={{
        position: 'absolute', bottom: 60, left: 60, right: 60,
        display: 'flex', flexDirection: 'column', gap: 10,
      }}>
        <FeatureTag icon="statistics.svg" text={t.stats.detailedAnalytics} startFrame={120} />
        <FeatureTag icon="calendar.svg" text={t.stats.autoEvents} startFrame={170} color={colors.accent} />
        <FeatureTag icon="notification.svg" text={t.stats.reminderSystem} startFrame={190} color={colors.success} />
      </div>
    </AbsoluteFill>
  );
};
