import React from 'react';
import { AbsoluteFill, useCurrentFrame, interpolate, staticFile } from 'remotion';
import { AnimatedText } from '../components/AnimatedText';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';
import { WIDTH, HEIGHT } from '../config/constants';
import type { Language } from '../i18n/types';
import { tr } from '../i18n/tr';
import { en } from '../i18n/en';

interface Scene07Props {
  lang: Language;
}

interface FeatureRowProps {
  emoji: string;
  icon?: string;
  title: string;
  subtitle: string;
  startFrame: number;
  color: string;
  frame: number;
}

const FeatureRow: React.FC<FeatureRowProps> = ({ emoji, icon, title, subtitle, startFrame, color, frame }) => {
  const localFrame = frame - startFrame;
  if (localFrame < 0) return null;

  const opacity = interpolate(localFrame, [0, 20], [0, 1], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });
  const x = interpolate(localFrame, [0, 20], [60, 0], { extrapolateRight: 'clamp', extrapolateLeft: 'clamp' });

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 20,
      padding: '20px 28px',
      background: `${color}08`,
      borderRadius: 20,
      borderLeft: `5px solid ${color}`,
      opacity,
      transform: `translateX(${x}px)`,
    }}>
      <div style={{
        width: 56, height: 56, borderRadius: 16,
        background: `${color}15`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 28,
        boxShadow: `0 4px 12px ${color}20`,
      }}>
        {icon ? (
          <img src={staticFile(`icons/${icon}`)} style={{ width: 28, height: 28 }} />
        ) : emoji}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontFamily, fontSize: 24, fontWeight: 700, color: colors.neutral900 }}>
          {title}
        </div>
        <div style={{ fontFamily, fontSize: 16, color: colors.neutral500, marginTop: 4 }}>
          {subtitle}
        </div>
      </div>
    </div>
  );
};

export const Scene07_SmartFeatures: React.FC<Scene07Props> = ({ lang }) => {
  const frame = useCurrentFrame();
  const t = lang === 'tr' ? tr : en;

  const features = [
    {
      emoji: '🔔', icon: 'notification.svg',
      title: t.smart.notifications,
      subtitle: t.smart.turnEggsReminder,
      color: colors.primary, startFrame: 15,
    },
    {
      emoji: '📡', icon: 'sync.svg',
      title: t.smart.cloudSync,
      subtitle: t.smart.worksOffline,
      color: colors.success, startFrame: 55,
    },
    {
      emoji: '🌍', icon: 'language.svg',
      title: t.smart.multiLanguage,
      subtitle: 'TR · EN · DE',
      color: colors.accent, startFrame: 95,
    },
    {
      emoji: '💾', icon: 'export.svg',
      title: t.smart.exportBackup,
      subtitle: t.smart.pdfExcel,
      color: colors.info, startFrame: 135,
    },
  ];

  return (
    <AbsoluteFill style={{ background: `linear-gradient(180deg, ${colors.neutral50}, ${colors.white})` }}>
      {/* Title */}
      <div style={{
        position: 'absolute', top: 80, left: 0, width: WIDTH, textAlign: 'center',
      }}>
        <AnimatedText
          text={t.smart.title}
          startFrame={0}
          fontSize={36}
          fontWeight={800}
          color={colors.primary}
          align="center"
          animation="scaleIn"
        />
      </div>

      {/* Feature rows */}
      <div style={{
        position: 'absolute', top: 200, left: 80, right: 80,
        display: 'flex', flexDirection: 'column', gap: 24,
      }}>
        {features.map((f, i) => (
          <FeatureRow key={i} {...f} frame={frame} />
        ))}
      </div>
    </AbsoluteFill>
  );
};
