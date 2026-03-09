import React from 'react';
import { AbsoluteFill, Sequence, useCurrentFrame } from 'remotion';
import { SCENES, TOTAL_FRAMES, TRANSITION_FRAMES } from '../config/constants';
import { ProgressBar } from '../components/ProgressBar';
import {
  Scene01_Intro,
  Scene02_Dashboard,
  Scene03_BirdManagement,
  Scene04_BreedingCycle,
  Scene05_GeneticsGenealogy,
  Scene06_StatsCalendar,
  Scene07_SmartFeatures,
  Scene08_PremiumCTA,
} from '../scenes';
import type { Language } from '../i18n/types';

export interface PromoVideoProps extends Record<string, unknown> {
  lang: Language;
}

export const PromoVideo: React.FC<PromoVideoProps> = ({ lang }) => {
  const frame = useCurrentFrame();

  // Cross-fade transition: fade out current scene in last TRANSITION_FRAMES,
  // fade in next scene in first TRANSITION_FRAMES
  const getSceneOpacity = (sceneStart: number, sceneDuration: number): number => {
    const localFrame = frame - sceneStart;

    // Not yet visible
    if (localFrame < 0) return 0;
    // Past this scene
    if (localFrame >= sceneDuration) return 0;

    // Fade in (first scene doesn't fade in)
    let opacity = 1;
    if (sceneStart > 0 && localFrame < TRANSITION_FRAMES) {
      opacity = localFrame / TRANSITION_FRAMES;
    }

    // Fade out (last scene doesn't fade out)
    const isLastScene = sceneStart === SCENES.premium.start;
    if (!isLastScene && localFrame > sceneDuration - TRANSITION_FRAMES) {
      opacity = Math.min(opacity, (sceneDuration - localFrame) / TRANSITION_FRAMES);
    }

    return Math.max(0, Math.min(1, opacity));
  };

  const scenes = [
    { key: 'intro', ...SCENES.intro, Component: Scene01_Intro },
    { key: 'dashboard', ...SCENES.dashboard, Component: Scene02_Dashboard },
    { key: 'birds', ...SCENES.birds, Component: Scene03_BirdManagement },
    { key: 'breeding', ...SCENES.breeding, Component: Scene04_BreedingCycle },
    { key: 'genetics', ...SCENES.genetics, Component: Scene05_GeneticsGenealogy },
    { key: 'stats', ...SCENES.stats, Component: Scene06_StatsCalendar },
    { key: 'smart', ...SCENES.smart, Component: Scene07_SmartFeatures },
    { key: 'premium', ...SCENES.premium, Component: Scene08_PremiumCTA },
  ];

  return (
    <AbsoluteFill style={{ backgroundColor: '#000' }}>
      {scenes.map(({ key, start, duration, Component }) => (
        <Sequence key={key} from={start} durationInFrames={duration} name={key}>
          <AbsoluteFill style={{ opacity: getSceneOpacity(start, duration) }}>
            <Component lang={lang} />
          </AbsoluteFill>
        </Sequence>
      ))}

      {/* Progress bar overlay - always visible */}
      <ProgressBar />
    </AbsoluteFill>
  );
};
