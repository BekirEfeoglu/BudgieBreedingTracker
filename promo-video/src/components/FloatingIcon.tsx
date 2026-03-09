import React from 'react';
import { useCurrentFrame, staticFile, interpolate } from 'remotion';

interface FloatingIconProps {
  icon: string; // SVG filename
  size?: number;
  x: number;
  y: number;
  delay?: number;
  floatAmount?: number;
  color?: string;
}

export const FloatingIcon: React.FC<FloatingIconProps> = ({
  icon,
  size = 48,
  x,
  y,
  delay = 0,
  floatAmount = 8,
  color,
}) => {
  const frame = useCurrentFrame();
  const localFrame = frame - delay;

  if (localFrame < 0) return null;

  // Fade in
  const opacity = interpolate(localFrame, [0, 20], [0, 0.6], {
    extrapolateRight: 'clamp',
  });

  // Floating bob animation (sine wave)
  const floatY = Math.sin((localFrame / 30) * Math.PI) * floatAmount;

  // Gentle rotation
  const rotation = Math.sin((localFrame / 50) * Math.PI) * 5;

  return (
    <img
      src={staticFile(`icons/${icon}`)}
      style={{
        position: 'absolute',
        left: x,
        top: y + floatY,
        width: size,
        height: size,
        opacity,
        transform: `rotate(${rotation}deg)`,
        filter: color ? `drop-shadow(0 0 8px ${color}40)` : undefined,
      }}
    />
  );
};
