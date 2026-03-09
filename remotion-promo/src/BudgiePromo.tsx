import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame, interpolate } from "remotion";
import { timing } from "./theme";
import { IntroScene } from "./components/IntroScene";
import { FeaturesScene } from "./components/FeaturesScene";
import { PhoneDemoScene } from "./components/PhoneMockup";
import { StatsScene } from "./components/StatsScene";
import { TechStackScene } from "./components/TechStackScene";
import { OutroScene } from "./components/OutroScene";

const SceneTransition: React.FC<{
  children: React.ReactNode;
  duration: number;
  fadeIn?: number;
  fadeOut?: number;
}> = ({ children, duration, fadeIn = 15, fadeOut = 15 }) => {
  const frame = useCurrentFrame();

  const opacity = interpolate(
    frame,
    [0, fadeIn, duration - fadeOut, duration],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill style={{ opacity }}>
      {children}
    </AbsoluteFill>
  );
};

export const BudgiePromo: React.FC = () => {
  const scenes = [
    { key: "intro",     config: timing.intro,     Component: IntroScene },
    { key: "features",  config: timing.features,   Component: FeaturesScene },
    { key: "phoneDemo", config: timing.phoneDemo,  Component: PhoneDemoScene },
    { key: "stats",     config: timing.stats,      Component: StatsScene },
    { key: "techStack", config: timing.techStack,   Component: TechStackScene },
    { key: "outro",     config: timing.outro,      Component: OutroScene },
  ];

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      {scenes.map(({ key, config, Component }) => (
        <Sequence key={key} from={config.from} durationInFrames={config.duration}>
          <SceneTransition duration={config.duration}>
            <Component />
          </SceneTransition>
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
