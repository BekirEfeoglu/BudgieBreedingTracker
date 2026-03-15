import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame, interpolate } from "remotion";
import { colors, timing, seededRandom } from "./theme";
import { IntroScene } from "./components/IntroScene";
import { FeaturesScene } from "./components/FeaturesScene";
import { PhoneDemoScene } from "./components/PhoneMockup";
import { StatsScene } from "./components/StatsScene";
import { TechStackScene } from "./components/TechStackScene";
import { OutroScene } from "./components/OutroScene";

// ─── Cinematic wipe transition ────────────────────────────────
const SceneTransition: React.FC<{
  children: React.ReactNode;
  duration: number;
  fadeIn?: number;
  fadeOut?: number;
}> = ({ children, duration, fadeIn = 12, fadeOut = 12 }) => {
  const frame = useCurrentFrame();

  const opacity = interpolate(
    frame,
    [0, fadeIn, duration - fadeOut, duration],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  const scale = interpolate(
    frame,
    [0, fadeIn, duration - fadeOut, duration],
    [1.04, 1, 1, 0.97],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Slide direction alternates
  const slideX = interpolate(
    frame,
    [0, fadeIn],
    [15, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill style={{ opacity, transform: `scale(${scale}) translateX(${slideX}px)` }}>
      {children}
    </AbsoluteFill>
  );
};

// ─── Global floating particle field ────────────────────────────
const GlobalParticles: React.FC = () => {
  const frame = useCurrentFrame();
  const particleCount = 30;

  return (
    <AbsoluteFill style={{ pointerEvents: "none", zIndex: 100, overflow: "hidden" }}>
      {[...Array(particleCount)].map((_, i) => {
        const r = seededRandom(i);
        const r2 = seededRandom(i + 100);
        const r3 = seededRandom(i + 200);
        const speed = 0.3 + r * 0.5;
        const x = r2 * 1920;
        const baseY = 1080 + 50;
        const y = baseY - ((frame * speed + r3 * 500) % (1080 + 100));
        const size = 1.5 + r * 2.5;
        const opacity = interpolate(y, [0, 200, 900, 1080], [0, 0.4, 0.4, 0]);
        const drift = Math.sin(frame * 0.02 + i) * 15;
        const isColored = i % 5 === 0;
        const color = isColored
          ? i % 10 === 0 ? colors.primary : colors.accent
          : "rgba(255,255,255,0.5)";

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x + drift,
              top: y,
              width: size,
              height: size,
              borderRadius: "50%",
              backgroundColor: color,
              opacity,
              boxShadow: isColored ? `0 0 ${size * 3}px ${color}` : undefined,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

export const BudgiePromo: React.FC = () => {
  const scenes = [
    { key: "intro",     config: timing.intro,     Component: IntroScene,    fadeIn: 6,  fadeOut: 14 },
    { key: "features",  config: timing.features,  Component: FeaturesScene, fadeIn: 12, fadeOut: 12 },
    { key: "phoneDemo", config: timing.phoneDemo, Component: PhoneDemoScene,fadeIn: 12, fadeOut: 12 },
    { key: "stats",     config: timing.stats,     Component: StatsScene,    fadeIn: 10, fadeOut: 10 },
    { key: "techStack", config: timing.techStack,  Component: TechStackScene,fadeIn: 10, fadeOut: 10 },
    { key: "outro",     config: timing.outro,     Component: OutroScene,    fadeIn: 10, fadeOut: 1 },
  ];

  return (
    <AbsoluteFill style={{ backgroundColor: "#030303", fontFamily: "'Inter', sans-serif" }}>
      <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" />
      <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Outfit:wght@500;700;800;900&display=swap" />

      {scenes.map(({ key, config, Component, fadeIn, fadeOut }) => (
        <Sequence key={key} from={config.from} durationInFrames={config.duration}>
          <SceneTransition duration={config.duration} fadeIn={fadeIn} fadeOut={fadeOut}>
            <Component />
          </SceneTransition>
        </Sequence>
      ))}

      {/* Global ambient particles — always visible across all scenes */}
      <GlobalParticles />
    </AbsoluteFill>
  );
};
