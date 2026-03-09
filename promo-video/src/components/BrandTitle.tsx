import React from 'react';
import { interpolate, useCurrentFrame, spring, useVideoConfig } from 'remotion';
import { colors } from '../config/colors';
import { fontFamily } from '../config/fonts';

interface BrandTitleProps {
  size?: 'small' | 'medium' | 'large';
  startFrame?: number;
  animated?: boolean;
}

export const BrandTitle: React.FC<BrandTitleProps> = ({
  size = 'medium',
  startFrame = 0,
  animated = true,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const localFrame = frame - startFrame;

  const fontSize = size === 'large' ? 52 : size === 'medium' ? 36 : 20;
  const letterSpacing = size === 'large' ? -1 : -0.5;

  const parts = [
    { text: 'Budgie', color: colors.primary, weight: 800, delay: 0 },
    { text: 'Breeding', color: colors.accent, weight: 600, delay: 8 },
    { text: 'Tracker', color: colors.primary, weight: 800, delay: 16 },
  ];

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'baseline',
        justifyContent: 'center',
      }}
    >
      {parts.map((part, i) => {
        let opacity = 1;
        let transform = 'none';

        if (animated && localFrame >= 0) {
          const partFrame = localFrame - part.delay;
          if (partFrame < 0) {
            opacity = 0;
          } else {
            const s = spring({
              frame: partFrame,
              fps,
              config: { damping: 14, stiffness: 100 },
            });
            opacity = s;
            transform = `translateY(${interpolate(s, [0, 1], [20, 0])}px)`;
          }
        }

        return (
          <span
            key={i}
            style={{
              fontFamily,
              fontSize,
              fontWeight: part.weight,
              color: part.color,
              letterSpacing,
              lineHeight: 1.2,
              opacity,
              transform,
              display: 'inline-block',
            }}
          >
            {part.text}
          </span>
        );
      })}
    </div>
  );
};
