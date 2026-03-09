import React from 'react';
import { interpolate, useCurrentFrame, spring, useVideoConfig } from 'remotion';
import { fontFamily } from '../config/fonts';

interface AnimatedTextProps {
  text: string;
  startFrame?: number;
  duration?: number;
  fontSize?: number;
  fontWeight?: number;
  color?: string;
  align?: 'left' | 'center' | 'right';
  style?: React.CSSProperties;
  animation?: 'fadeUp' | 'fadeIn' | 'slideLeft' | 'scaleIn';
}

export const AnimatedText: React.FC<AnimatedTextProps> = ({
  text,
  startFrame = 0,
  duration = 30,
  fontSize = 32,
  fontWeight = 600,
  color = '#1E293B',
  align = 'left',
  style,
  animation = 'fadeUp',
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const localFrame = frame - startFrame;

  if (localFrame < 0) return null;

  let opacity: number;
  let transform: string;

  switch (animation) {
    case 'fadeUp': {
      opacity = interpolate(localFrame, [0, duration], [0, 1], {
        extrapolateRight: 'clamp',
      });
      const y = interpolate(localFrame, [0, duration], [30, 0], {
        extrapolateRight: 'clamp',
      });
      transform = `translateY(${y}px)`;
      break;
    }
    case 'fadeIn': {
      opacity = interpolate(localFrame, [0, duration], [0, 1], {
        extrapolateRight: 'clamp',
      });
      transform = 'none';
      break;
    }
    case 'slideLeft': {
      opacity = interpolate(localFrame, [0, duration * 0.6], [0, 1], {
        extrapolateRight: 'clamp',
      });
      const x = interpolate(localFrame, [0, duration], [60, 0], {
        extrapolateRight: 'clamp',
      });
      transform = `translateX(${x}px)`;
      break;
    }
    case 'scaleIn': {
      const s = spring({ frame: localFrame, fps, config: { damping: 12, stiffness: 120 } });
      opacity = s;
      transform = `scale(${interpolate(s, [0, 1], [0.5, 1])})`;
      break;
    }
  }

  return (
    <div
      style={{
        fontFamily,
        fontSize,
        fontWeight,
        color,
        textAlign: align,
        opacity,
        transform,
        lineHeight: 1.3,
        ...style,
      }}
    >
      {text}
    </div>
  );
};
