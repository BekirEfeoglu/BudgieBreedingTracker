import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from 'remotion';
import { PhoneMockup } from '../components/PhoneMockup';
import { PhoneStatusBar } from '../components/PhoneStatusBar';
import { MockGeneticsWizard } from '../mockup-screens/MockGeneticsWizard';
import { MockFamilyTree } from '../mockup-screens/MockFamilyTree';
import { FeatureTag } from '../components/FeatureTag';
import { PremiumBadge } from '../components/PremiumBadge';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import { WIDTH, HEIGHT } from '../config/constants';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface Scene05Props {
  lang: Language;
}

export const Scene05_GeneticsGenealogy: React.FC<Scene05Props> = ({ lang }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = lang === 'tr' ? tr : en;

  // Two sub-phases: genetics(0-210), genealogy(210-360)
  const phase = frame < 210 ? 0 : 1;
  const phaseFrame = frame < 210 ? frame : frame - 210;

  const phoneSpring = spring({ frame, fps, config: { damping: 14, stiffness: 90 } });

  const transitionOpacity = (targetPhase: number) => {
    if (phase === targetPhase) {
      const fadeIn = interpolate(phaseFrame, [0, 15], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
      return fadeIn;
    }
    if (phase > targetPhase) {
      return interpolate(frame, [210, 225], [1, 0], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
    }
    return 0;
  };

  return (
    <AbsoluteFill style={{ background: colors.neutral50 }}>
      {/* Section title */}
      <div style={{
        position: 'absolute', top: 50, left: 0, width: WIDTH,
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
      }}>
        <div style={{ fontFamily, fontSize: 18, fontWeight: 700, color: colors.primary, letterSpacing: 2, textTransform: 'uppercase' }}>
          {t.genetics.title}
        </div>
        <PremiumBadge startFrame={20} size="small" />
      </div>

      {/* Phone */}
      <div style={{
        position: 'absolute',
        top: HEIGHT * 0.09,
        left: (WIDTH - 356) / 2,
        opacity: phoneSpring,
      }}>
        <PhoneMockup scale={1.1}>
          <PhoneStatusBar />
          <div style={{ position: 'relative', width: '100%', height: '100%' }}>
            <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', opacity: transitionOpacity(0) }}>
              <MockGeneticsWizard frame={phaseFrame} lang={lang} />
            </div>
            <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', opacity: transitionOpacity(1) }}>
              <MockFamilyTree frame={phaseFrame} lang={lang} />
            </div>
          </div>
        </PhoneMockup>
      </div>

      {/* Feature tags */}
      <div style={{
        position: 'absolute', bottom: 60, left: 60, right: 60,
        display: 'flex', flexDirection: 'column', gap: 10,
      }}>
        <FeatureTag icon="punnett.svg" text={t.genetics.punnettSquare} startFrame={180} />
        <FeatureTag icon="dna.svg" text={t.genetics.mutationDatabase} startFrame={200} color={colors.accent} />
        <FeatureTag icon="genealogy.svg" text={t.genetics.interactiveTree} startFrame={230} color={colors.success} />
      </div>
    </AbsoluteFill>
  );
};
