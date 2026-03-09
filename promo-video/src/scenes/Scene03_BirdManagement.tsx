import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import { PhoneMockup } from '../components/PhoneMockup';
import { PhoneStatusBar } from '../components/PhoneStatusBar';
import { PhoneNavBar } from '../components/PhoneNavBar';
import { MockBirdList } from '../mockup-screens/MockBirdList';
import { FeatureTag } from '../components/FeatureTag';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import { WIDTH, HEIGHT } from '../config/constants';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface Scene03Props {
  lang: Language;
}

export const Scene03_BirdManagement: React.FC<Scene03Props> = ({ lang }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = lang === 'tr' ? tr : en;

  const phoneSpring = spring({ frame, fps, config: { damping: 15, stiffness: 80 } });
  const phoneX = interpolate(phoneSpring, [0, 1], [400, 0]);

  const titleOpacity = interpolate(frame, [10, 30], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  return (
    <AbsoluteFill style={{ background: colors.neutral50 }}>
      {/* Section title */}
      <div style={{
        position: 'absolute', top: 60, left: 0, width: WIDTH, textAlign: 'center',
        opacity: titleOpacity,
      }}>
        <div style={{ fontFamily, fontSize: 18, fontWeight: 700, color: colors.primary, letterSpacing: 2, textTransform: 'uppercase' }}>
          {t.birds.title}
        </div>
      </div>

      {/* Phone */}
      <div style={{
        position: 'absolute',
        top: HEIGHT * 0.08,
        left: (WIDTH - 356) / 2,
        opacity: phoneSpring,
        transform: `translateX(${phoneX}px)`,
      }}>
        <PhoneMockup scale={1.15}>
          <PhoneStatusBar />
          <MockBirdList frame={frame} lang={lang} />
          <PhoneNavBar activeTab="birds" />
        </PhoneMockup>
      </div>

      {/* Feature tags */}
      <div style={{
        position: 'absolute', bottom: 80, left: 60, right: 60,
        display: 'flex', flexDirection: 'column', gap: 12,
      }}>
        <FeatureTag icon="bird.svg" text={t.birds.detailedProfiles} startFrame={150} />
        <FeatureTag icon="photo.svg" text={t.birds.photoGallery} startFrame={170} color={colors.accent} />
        <FeatureTag icon="ring.svg" text={t.birds.ringTracking} startFrame={190} color={colors.info} />
        <FeatureTag text={t.birds.smartFiltering} startFrame={210} color={colors.success} />
      </div>
    </AbsoluteFill>
  );
};
