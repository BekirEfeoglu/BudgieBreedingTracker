import React from 'react';
import { useCurrentFrame } from 'remotion';
import { TOTAL_FRAMES, WIDTH } from '../config/constants';
import { colors } from '../config/colors';

export const ProgressBar: React.FC = () => {
  const frame = useCurrentFrame();
  const progress = frame / TOTAL_FRAMES;

  return (
    <div
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        width: WIDTH,
        height: 4,
        background: `${colors.neutral200}80`,
        zIndex: 100,
      }}
    >
      <div
        style={{
          width: WIDTH * progress,
          height: '100%',
          background: `linear-gradient(90deg, ${colors.primary}, ${colors.accent})`,
          borderRadius: '0 2px 2px 0',
        }}
      />
    </div>
  );
};
