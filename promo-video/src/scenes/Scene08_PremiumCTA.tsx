import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, staticFile, Img } from 'remotion';
import { GradientBackground } from '../components/GradientBackground';
import { PremiumBadge } from '../components/PremiumBadge';
import { AnimatedText } from '../components/AnimatedText';
import { BrandTitle } from '../components/BrandTitle';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import { WIDTH } from '../config/constants';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface Scene08Props {
  lang: Language;
}

export const Scene08_PremiumCTA: React.FC<Scene08Props> = ({ lang }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = lang === 'tr' ? tr : en;

  const features = [
    { text: t.premium.geneticsCalc, emoji: '🧬' },
    { text: t.premium.familyTree, emoji: '🌳' },
    { text: t.premium.advancedStats, emoji: '📊' },
    { text: t.premium.unlimitedBirds, emoji: '🐦' },
    { text: t.premium.prioritySupport, emoji: '⭐' },
    { text: t.premium.noAds, emoji: '🚫' },
  ];

  // CTA button pulse
  const pulse = Math.sin((frame / 10) * Math.PI) * 0.03 + 1;
  const ctaOpacity = interpolate(frame, [200, 220], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  return (
    <AbsoluteFill>
      <GradientBackground
        colors={['#1a0a00', '#3D1400', '#1E40AF']}
        direction="radial"
      >
        {/* Premium badge */}
        <div style={{
          position: 'absolute', top: 100, left: 0, width: WIDTH,
          display: 'flex', flexDirection: 'column', alignItems: 'center',
        }}>
          <PremiumBadge startFrame={15} size="large" label={t.premium.unlockAll} />
        </div>

        {/* Title */}
        <div style={{
          position: 'absolute', top: 200, left: 0, width: WIDTH, textAlign: 'center',
        }}>
          <AnimatedText
            text={t.premium.title}
            startFrame={40}
            fontSize={32}
            fontWeight={700}
            color={colors.white}
            align="center"
            animation="fadeUp"
          />
        </div>

        {/* Feature checklist */}
        <div style={{
          position: 'absolute', top: 320, left: 100, right: 100,
          display: 'flex', flexDirection: 'column', gap: 18,
        }}>
          {features.map((f, i) => {
            const delay = 70 + i * 15;
            const opacity = interpolate(frame, [delay, delay + 15], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
            const x = interpolate(frame, [delay, delay + 15], [30, 0], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
            return (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 16,
                opacity, transform: `translateX(${x}px)`,
              }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 18,
                  background: 'rgba(255,255,255,0.1)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 18,
                }}>
                  {f.emoji}
                </div>
                <span style={{
                  fontFamily, fontSize: 22, fontWeight: 500, color: 'rgba(255,255,255,0.9)',
                }}>
                  {f.text}
                </span>
                <span style={{ marginLeft: 'auto', color: colors.success, fontSize: 18 }}>✓</span>
              </div>
            );
          })}
        </div>

        {/* Pricing cards */}
        <div style={{
          position: 'absolute', bottom: 340, left: 80, right: 80,
          display: 'flex', gap: 16,
          opacity: interpolate(frame, [170, 190], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }),
        }}>
          {/* Monthly */}
          <div style={{
            flex: 1, background: 'rgba(255,255,255,0.08)',
            borderRadius: 16, padding: '18px 12px', textAlign: 'center',
            border: '1px solid rgba(255,255,255,0.1)',
          }}>
            <div style={{ fontFamily, fontSize: 13, color: 'rgba(255,255,255,0.6)', marginBottom: 6 }}>
              {lang === 'tr' ? 'Aylik' : 'Monthly'}
            </div>
            <div style={{ fontFamily, fontSize: 24, fontWeight: 800, color: colors.white }}>
              {t.premium.monthly}
            </div>
          </div>

          {/* Yearly - highlighted */}
          <div style={{
            flex: 1,
            background: `linear-gradient(135deg, ${colors.premiumGold}20, ${colors.premiumGoldDark}15)`,
            borderRadius: 16, padding: '18px 12px', textAlign: 'center',
            border: `1.5px solid ${colors.premiumGold}60`,
            position: 'relative',
          }}>
            {/* Best value badge */}
            <div style={{
              position: 'absolute', top: -10, left: '50%', transform: 'translateX(-50%)',
              background: colors.premiumGold, borderRadius: 10,
              padding: '2px 10px',
              fontFamily, fontSize: 9, fontWeight: 700, color: '#000',
            }}>
              {lang === 'tr' ? 'EN AVANTAJLI' : 'BEST VALUE'}
            </div>
            <div style={{ fontFamily, fontSize: 13, color: 'rgba(255,255,255,0.6)', marginBottom: 6 }}>
              {lang === 'tr' ? 'Yillik' : 'Yearly'}
            </div>
            <div style={{ fontFamily, fontSize: 24, fontWeight: 800, color: colors.premiumGold }}>
              {t.premium.yearly}
            </div>
          </div>
        </div>

        {/* CTA Button */}
        <div style={{
          position: 'absolute', bottom: 200, left: 100, right: 100,
          opacity: ctaOpacity,
          transform: `scale(${pulse})`,
        }}>
          <div style={{
            background: `linear-gradient(135deg, ${colors.accent}, ${colors.accentLight})`,
            borderRadius: 20, padding: '20px 0', textAlign: 'center',
            boxShadow: `0 8px 30px ${colors.accent}40`,
          }}>
            <span style={{ fontFamily, fontSize: 22, fontWeight: 800, color: colors.white }}>
              {t.premium.startFreeTrial}
            </span>
          </div>
        </div>

        {/* Brand at bottom */}
        <div style={{
          position: 'absolute', bottom: 120, left: 0, width: WIDTH,
          display: 'flex', justifyContent: 'center',
          opacity: interpolate(frame, [240, 260], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' }),
        }}>
          <BrandTitle size="small" animated={false} />
        </div>
      </GradientBackground>
    </AbsoluteFill>
  );
};
