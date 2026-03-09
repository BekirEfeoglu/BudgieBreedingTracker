import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, staticFile, Img } from 'remotion';
import { GradientBackground } from '../components/GradientBackground';
import { BrandTitle } from '../components/BrandTitle';
import { AnimatedText } from '../components/AnimatedText';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import { WIDTH, HEIGHT } from '../config/constants';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface Scene01Props {
  lang: Language;
}

export const Scene01_Intro: React.FC<Scene01Props> = ({ lang }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = lang === 'tr' ? tr : en;

  // Logo animation
  const logoSpring = spring({ frame: frame - 15, fps, config: { damping: 12, stiffness: 100 } });
  const logoScale = interpolate(logoSpring, [0, 1], [0, 1]);
  const logoOpacity = logoSpring;

  // Particle decorations
  const particles = Array.from({ length: 12 }, (_, i) => ({
    x: WIDTH * 0.15 + (i % 4) * (WIDTH * 0.22),
    y: HEIGHT * 0.18 + Math.floor(i / 4) * 180,
    size: 6 + (i % 3) * 4,
    delay: 40 + i * 4,
    speed: 0.5 + (i % 3) * 0.3,
  }));

  return (
    <AbsoluteFill>
      <GradientBackground colors={[colors.neutral950, colors.primaryDark, colors.primary]} direction="radial">
        {/* Decorative particles */}
        {particles.map((p, i) => {
          const pOpacity = interpolate(frame, [p.delay, p.delay + 20], [0, 0.3], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
          const floatY = Math.sin(((frame - p.delay) * p.speed * Math.PI) / 60) * 15;
          return (
            <div key={i} style={{
              position: 'absolute', left: p.x, top: p.y + floatY,
              width: p.size, height: p.size, borderRadius: '50%',
              background: i % 2 === 0 ? colors.accent : colors.primaryLight,
              opacity: pOpacity,
              filter: 'blur(1px)',
            }} />
          );
        })}

        {/* Center content */}
        <div style={{
          position: 'absolute', top: 0, left: 0, width: WIDTH, height: HEIGHT,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        }}>
          {/* App Logo */}
          <div style={{
            opacity: logoOpacity,
            transform: `scale(${logoScale})`,
            marginBottom: 40,
          }}>
            <div style={{
              width: 160, height: 160,
              borderRadius: 36,
              overflow: 'hidden',
              boxShadow: `0 20px 60px ${colors.primary}50, 0 8px 24px rgba(0,0,0,0.3)`,
            }}>
              <Img src={staticFile('images/app_logo.png')} style={{ width: 160, height: 160 }} />
            </div>
          </div>

          {/* Brand Title */}
          <div style={{ marginBottom: 30 }}>
            <BrandTitle size="large" startFrame={50} animated />
          </div>

          {/* Slogan */}
          <AnimatedText
            text={t.intro.slogan}
            startFrame={90}
            duration={30}
            fontSize={30}
            fontWeight={500}
            color={colors.neutral200}
            align="center"
            animation="fadeUp"
          />

          {/* Tagline */}
          <AnimatedText
            text={t.intro.tagline}
            startFrame={120}
            duration={25}
            fontSize={18}
            fontWeight={400}
            color={colors.neutral400}
            align="center"
            animation="fadeIn"
            style={{ marginTop: 12 }}
          />
        </div>
      </GradientBackground>
    </AbsoluteFill>
  );
};
