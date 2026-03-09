import React from 'react';
import { interpolate, useCurrentFrame, staticFile } from 'remotion';
import { fontFamily } from '../config/fonts';
import { colors } from '../config/colors';

interface FeatureTagProps {
  icon?: string; // SVG filename in public/icons/
  text: string;
  startFrame?: number;
  color?: string;
  bgColor?: string;
  fontSize?: number;
}

export const FeatureTag: React.FC<FeatureTagProps> = ({
  icon,
  text,
  startFrame = 0,
  color = colors.primary,
  bgColor,
  fontSize = 28,
}) => {
  const frame = useCurrentFrame();
  const localFrame = frame - startFrame;

  if (localFrame < 0) return null;

  const opacity = interpolate(localFrame, [0, 20], [0, 1], {
    extrapolateRight: 'clamp',
  });
  const x = interpolate(localFrame, [0, 20], [40, 0], {
    extrapolateRight: 'clamp',
  });

  const bg = bgColor || `${color}15`;

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 14,
        padding: '14px 22px',
        background: bg,
        borderRadius: 16,
        borderLeft: `4px solid ${color}`,
        opacity,
        transform: `translateX(${x}px)`,
      }}
    >
      {icon && (
        <img
          src={staticFile(`icons/${icon}`)}
          style={{ width: 28, height: 28 }}
        />
      )}
      <span
        style={{
          fontFamily,
          fontSize,
          fontWeight: 600,
          color: colors.neutral800,
          lineHeight: 1.3,
        }}
      >
        {text}
      </span>
    </div>
  );
};
