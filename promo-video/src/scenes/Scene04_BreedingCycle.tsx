import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import { PhoneMockup } from '../components/PhoneMockup';
import { PhoneStatusBar } from '../components/PhoneStatusBar';
import { PhoneNavBar } from '../components/PhoneNavBar';
import { MockBreedingDetail } from '../mockup-screens/MockBreedingDetail';
import { MockEggTimeline } from '../mockup-screens/MockEggTimeline';
import { MockChickGrowth } from '../mockup-screens/MockChickGrowth';
import { FeatureTag } from '../components/FeatureTag';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import { WIDTH, HEIGHT } from '../config/constants';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface Scene04Props {
  lang: Language;
}

export const Scene04_BreedingCycle: React.FC<Scene04Props> = ({ lang }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = lang === 'tr' ? tr : en;

  // Three sub-phases: breeding(0-140), eggs(140-280), chicks(280-420)
  const phase = frame < 140 ? 0 : frame < 280 ? 1 : 2;
  const phaseFrame = frame < 140 ? frame : frame < 280 ? frame - 140 : frame - 280;

  const phoneSpring = spring({ frame, fps, config: { damping: 15, stiffness: 80 } });

  // Screen transition
  const transitionOpacity = (targetPhase: number) => {
    if (phase === targetPhase) {
      const fadeIn = interpolate(phaseFrame, [0, 15], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
      const fadeOut = interpolate(phaseFrame, [120, 140], [1, 0], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
      return Math.min(fadeIn, fadeOut);
    }
    return 0;
  };

  const titleOpacity = interpolate(frame, [5, 25], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  // Phase labels
  const phaseLabels = [
    { emoji: '💕', text: lang === 'tr' ? 'Ureme Cifti' : 'Breeding Pair' },
    { emoji: '🥚', text: lang === 'tr' ? 'Yumurta Takibi' : 'Egg Tracking' },
    { emoji: '🐤', text: lang === 'tr' ? 'Yavru Buyume' : 'Chick Growth' },
  ];

  return (
    <AbsoluteFill style={{ background: colors.neutral50 }}>
      {/* Section title */}
      <div style={{
        position: 'absolute', top: 60, left: 0, width: WIDTH, textAlign: 'center',
        opacity: titleOpacity,
      }}>
        <div style={{ fontFamily, fontSize: 18, fontWeight: 700, color: colors.primary, letterSpacing: 2, textTransform: 'uppercase' }}>
          {t.breeding.title}
        </div>
      </div>

      {/* Phase indicator dots */}
      <div style={{
        position: 'absolute', top: 100, left: 0, width: WIDTH,
        display: 'flex', justifyContent: 'center', gap: 12,
      }}>
        {phaseLabels.map((pl, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '6px 14px', borderRadius: 20,
            background: i === phase ? `${colors.primary}15` : 'transparent',
            border: i === phase ? `1.5px solid ${colors.primary}` : `1px solid ${colors.neutral200}`,
          }}>
            <span style={{ fontSize: 14 }}>{pl.emoji}</span>
            <span style={{
              fontFamily, fontSize: 11, fontWeight: i === phase ? 600 : 400,
              color: i === phase ? colors.primary : colors.neutral400,
            }}>
              {pl.text}
            </span>
          </div>
        ))}
      </div>

      {/* Phone - breeding detail */}
      <div style={{
        position: 'absolute',
        top: HEIGHT * 0.1,
        left: (WIDTH - 356) / 2,
        opacity: phoneSpring,
      }}>
        <PhoneMockup scale={1.1}>
          <PhoneStatusBar />
          <div style={{ position: 'relative', width: '100%', height: '100%' }}>
            <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', opacity: transitionOpacity(0) }}>
              <MockBreedingDetail frame={phaseFrame} lang={lang} />
            </div>
            <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', opacity: transitionOpacity(1) }}>
              <MockEggTimeline frame={phaseFrame} lang={lang} />
            </div>
            <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', opacity: transitionOpacity(2) }}>
              <MockChickGrowth frame={phaseFrame} lang={lang} />
            </div>
          </div>
          <PhoneNavBar activeTab="breeding" />
        </PhoneMockup>
      </div>

      {/* Feature tags */}
      <div style={{
        position: 'absolute', bottom: 60, left: 60, right: 60,
        display: 'flex', flexDirection: 'column', gap: 10,
      }}>
        <FeatureTag icon="incubation.svg" text={t.breeding.incubationTracking} startFrame={160} />
        <FeatureTag icon="egg.svg" text={t.breeding.eggManagement} startFrame={180} color={colors.accent} />
        <FeatureTag icon="growth.svg" text={t.breeding.chickTracking} startFrame={200} color={colors.success} />
      </div>
    </AbsoluteFill>
  );
};
