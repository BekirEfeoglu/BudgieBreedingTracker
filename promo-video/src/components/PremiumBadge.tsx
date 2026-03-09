import React from 'react';
import { interpolate, useCurrentFrame } from 'remotion';
import { fontFamily } from '../config/fonts';
import { colors } from '../config/colors';

interface PremiumBadgeProps {
  startFrame?: number;
  size?: 'small' | 'large';
  label?: string;
}

export const PremiumBadge: React.FC<PremiumBadgeProps> = ({
  startFrame = 0,
  size = 'small',
  label = 'PREMIUM',
}) => {
  const frame = useCurrentFrame();
  const localFrame = frame - startFrame;

  if (localFrame < 0) return null;

  const opacity = interpolate(localFrame, [0, 15], [0, 1], {
    extrapolateRight: 'clamp',
  });

  const scale = interpolate(localFrame, [0, 15], [0.6, 1], {
    extrapolateRight: 'clamp',
  });

  // Shimmer effect
  const shimmerX = interpolate(localFrame % 60, [0, 60], [-100, 200], {
    extrapolateRight: 'clamp',
  });

  const isLarge = size === 'large';
  const padding = isLarge ? '16px 36px' : '6px 16px';
  const fontSize = isLarge ? 22 : 12;

  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 8,
        padding,
        background: `linear-gradient(135deg, ${colors.premiumGold}, ${colors.premiumGoldDark})`,
        borderRadius: isLarge ? 16 : 20,
        opacity,
        transform: `scale(${scale})`,
        position: 'relative',
        overflow: 'hidden',
        boxShadow: isLarge ? '0 8px 32px rgba(255,215,0,0.3)' : '0 2px 8px rgba(255,215,0,0.3)',
      }}
    >
      {/* Shimmer overlay */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: shimmerX,
          width: 40,
          height: '100%',
          background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent)',
          transform: 'skewX(-20deg)',
        }}
      />

      {/* Crown icon */}
      <span style={{ fontSize: isLarge ? 28 : 14 }}>👑</span>

      <span
        style={{
          fontFamily,
          fontSize,
          fontWeight: 800,
          color: '#FFFFFF',
          letterSpacing: 1.5,
          textShadow: '0 1px 2px rgba(0,0,0,0.2)',
        }}
      >
        {label}
      </span>
    </div>
  );
};
