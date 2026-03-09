import React from 'react';
import { Composition } from 'remotion';
import { PromoVideo, type PromoVideoProps } from './compositions/PromoVideo';
import { FPS, WIDTH, HEIGHT, TOTAL_FRAMES } from './config/constants';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="PromoVideo-TR"
        component={PromoVideo as React.FC<Record<string, unknown>>}
        durationInFrames={TOTAL_FRAMES}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
        defaultProps={{ lang: 'tr' }}
      />
      <Composition
        id="PromoVideo-EN"
        component={PromoVideo as React.FC<Record<string, unknown>>}
        durationInFrames={TOTAL_FRAMES}
        fps={FPS}
        width={WIDTH}
        height={HEIGHT}
        defaultProps={{ lang: 'en' }}
      />
    </>
  );
};
