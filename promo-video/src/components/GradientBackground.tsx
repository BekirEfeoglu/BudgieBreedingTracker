import React from 'react';
import { AbsoluteFill } from 'remotion';
import { WIDTH, HEIGHT } from '../config/constants';

interface GradientBackgroundProps {
  colors: [string, string] | [string, string, string];
  direction?: 'vertical' | 'radial' | 'diagonal';
  children?: React.ReactNode;
}

export const GradientBackground: React.FC<GradientBackgroundProps> = ({
  colors,
  direction = 'vertical',
  children,
}) => {
  const gradient =
    direction === 'radial'
      ? `radial-gradient(ellipse at 50% 30%, ${colors.join(', ')})`
      : direction === 'diagonal'
        ? `linear-gradient(135deg, ${colors.join(', ')})`
        : `linear-gradient(180deg, ${colors.join(', ')})`;

  return (
    <AbsoluteFill
      style={{
        background: gradient,
        width: WIDTH,
        height: HEIGHT,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};
