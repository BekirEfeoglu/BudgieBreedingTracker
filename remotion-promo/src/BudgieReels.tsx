import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame, interpolate } from "remotion";
import { colors, timingReels, seededRandom } from "./theme";
import { IntroSceneReels } from "./components/IntroSceneReels";
import { FeaturesSceneReels } from "./components/FeaturesSceneReels";
import { PhoneDemoSceneReels } from "./components/PhoneMockupReels";
import { StatsSceneReels } from "./components/StatsSceneReels";
import { TechStackSceneReels } from "./components/TechStackSceneReels";
import { OutroSceneReels } from "./components/OutroSceneReels";

// ─── Reels-style vertical wipe transition ──────────────────────
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
    [1.06, 1, 1, 0.96],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Vertical slide transition (common in Reels)
  const slideY = interpolate(
    frame,
    [0, fadeIn],
    [30, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill style={{ opacity, transform: `scale(${scale}) translateY(${slideY}px)` }}>
      {children}
    </AbsoluteFill>
  );
};

// ─── Global floating particle field for vertical screens ────────
const GlobalParticlesReels: React.FC = () => {
  const frame = useCurrentFrame();
  const particleCount = 25; // Slightly lower for narrow screen to avoid clutter

  return (
    <AbsoluteFill style={{ pointerEvents: "none", zIndex: 100, overflow: "hidden" }}>
      {[...Array(particleCount)].map((_, i) => {
        const r = seededRandom(i);
        const r2 = seededRandom(i + 100);
        const r3 = seededRandom(i + 200);
        const speed = 0.4 + r * 0.6;
        const x = r2 * 1080; // Optimized for 1080px width
        const baseY = 1920 + 50; // Optimized for 1920px height
        const y = baseY - ((frame * speed + r3 * 800) % (1920 + 100));
        const size = 2 + r * 4;
        const opacity = interpolate(y, [0, 200, 1720, 1920], [0, 0.45, 0.45, 0]);
        const drift = Math.sin(frame * 0.025 + i) * 20;
        const isColored = i % 4 === 0;
        const color = isColored
          ? i % 8 === 0 ? colors.primary : colors.accent
          : "rgba(255,255,255,0.45)";

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

export const BudgieReels: React.FC = () => {
  const scenes = [
    { key: "intro",     config: timingReels.intro,     Component: IntroSceneReels,    fadeIn: 6,  fadeOut: 14 },
    { key: "features",  config: timingReels.features,  Component: FeaturesSceneReels, fadeIn: 12, fadeOut: 12 },
    { key: "phoneDemo", config: timingReels.phoneDemo, Component: PhoneDemoSceneReels,fadeIn: 12, fadeOut: 12 },
    { key: "stats",     config: timingReels.stats,     Component: StatsSceneReels,    fadeIn: 10, fadeOut: 10 },
    { key: "techStack", config: timingReels.techStack,  Component: TechStackSceneReels,fadeIn: 10, fadeOut: 10 },
    { key: "outro",     config: timingReels.outro,     Component: OutroSceneReels,    fadeIn: 10, fadeOut: 1 },
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
      <GlobalParticlesReels />
    </AbsoluteFill>
  );
};
