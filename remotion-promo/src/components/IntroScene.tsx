import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets, seededRandom } from "../theme";
import { BudgieIcon } from "./BudgieIcon";

// ─── Shockwave ring effect ──────────────────────────────────
const Shockwave: React.FC<{ trigger: number; color: string }> = ({ trigger, color }) => {
  const frame = useCurrentFrame();
  const elapsed = frame - trigger;
  if (elapsed < 0 || elapsed > 40) return null;
  const progress = elapsed / 40;
  const size = progress * 800;
  const opacity = interpolate(progress, [0, 0.2, 1], [0, 0.6, 0]);
  return (
    <div style={{
      position: "absolute", width: size, height: size, borderRadius: "50%",
      border: `2px solid ${color}`, opacity,
      transform: `scale(${1 + progress * 0.5})`,
      boxShadow: `0 0 30px ${color}40`,
    }} />
  );
};

// ─── Lens flare ─────────────────────────────────────────────
const LensFlare: React.FC<{ delay: number }> = ({ delay }) => {
  const frame = useCurrentFrame();
  const elapsed = Math.max(0, frame - delay);
  const progress = interpolate(elapsed, [0, 20, 50], [0, 1, 0], { extrapolateRight: "clamp" });
  if (progress <= 0) return null;
  return (
    <div style={{
      position: "absolute",
      width: 600, height: 4,
      background: `linear-gradient(90deg, transparent, ${colors.primary}80, ${colors.budgieYellow}60, transparent)`,
      opacity: progress * 0.7,
      filter: "blur(2px)",
      transform: `rotate(-15deg) scaleX(${progress})`,
    }} />
  );
};

export const IntroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ── Logo entrance ──
  const logoScale = spring({ frame, fps, config: { ...springPresets.pop, stiffness: 200 } });
  const logoRotate = interpolate(logoScale, [0, 0.5, 1], [-20, 5, 0]);
  const logoPulse = frame > 30 ? 1 + Math.sin((frame - 30) * 0.08) * 0.025 : 1;
  const logoFloat = frame > 40 ? Math.sin((frame - 40) * 0.04) * 3 : 0;

  // ── Title ──
  const titleText = "BudgieBreedingTracker";
  const titleStart = 15;

  // ── Subtitle ──
  const subtitleProgress = spring({ frame: Math.max(0, frame - 50), fps, config: springPresets.smooth });

  // ── Background ──
  const gradientAngle = interpolate(frame, [0, 180], [130, 170]);
  const bgBrightness = interpolate(frame, [0, 8, 15], [0, 0.3, 1], { extrapolateRight: "clamp" });

  // ── Orbs ──
  const orbData = Array.from({ length: 7 }, (_, i) => ({
    speed: 0.015 + seededRandom(i) * 0.015,
    radius: 200 + seededRandom(i + 10) * 200,
    size: 250 + seededRandom(i + 20) * 200,
    hue: 80 + seededRandom(i + 30) * 100,
  }));

  // ── Badges ──
  const badges = [
    { label: "Offline-First", icon: "📱" },
    { label: "3 Dil", icon: "🌍" },
    { label: "AES-256", icon: "🔐" },
    { label: "27 Mutasyon", icon: "🧬" },
  ];

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(${gradientAngle}deg, #040A06 0%, ${colors.gradient.start} 25%, ${colors.gradient.mid} 55%, ${colors.gradient.end} 100%)`,
        justifyContent: "center",
        alignItems: "center",
        overflow: "hidden",
        opacity: bgBrightness,
      }}
    >
      {/* Animated orbs */}
      {orbData.map((orb, i) => {
        const x = Math.sin(frame * orb.speed + i * 1.8) * orb.radius;
        const y = Math.cos(frame * orb.speed * 0.7 + i * 1.3) * (orb.radius * 0.5);
        return (
          <div key={i} style={{
            position: "absolute", width: orb.size, height: orb.size, borderRadius: "50%",
            background: `radial-gradient(circle, hsla(${orb.hue}, 65%, 35%, 0.18) 0%, transparent 70%)`,
            transform: `translate(${x}px, ${y}px)`, filter: "blur(50px)",
          }} />
        );
      })}

      {/* Perspective mesh grid */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `
          linear-gradient(rgba(20,241,149,0.03) 1px, transparent 1px),
          linear-gradient(90deg, rgba(20,241,149,0.03) 1px, transparent 1px)
        `,
        backgroundSize: "50px 50px",
        transform: `perspective(700px) rotateX(65deg) translateY(${-80 + frame * 0.7}px)`,
        transformOrigin: "center top",
        opacity: interpolate(frame, [0, 20], [0, 0.6], { extrapolateRight: "clamp" }),
      }} />

      {/* Sparkle field (40 particles) */}
      {[...Array(40)].map((_, i) => {
        const life = (frame + i * 13) % 80;
        const startX = (seededRandom(i + 500) * 2000) - 1000;
        const startY = (seededRandom(i + 600) * 1200) - 600;
        const opacity = interpolate(life, [0, 8, 55, 80], [0, 0.8, 0.6, 0]);
        const scale = interpolate(life, [0, 8, 80], [0, 1, 0.1]);
        const drift = life * 0.5;
        const isGold = i % 5 === 0;
        const isPrimary = i % 7 === 0;
        const color = isGold ? colors.budgieYellow : isPrimary ? colors.primary : "rgba(255,255,255,0.5)";
        return (
          <div key={i} style={{
            position: "absolute", width: isGold ? 5 : 2.5, height: isGold ? 5 : 2.5,
            borderRadius: "50%", backgroundColor: color, opacity,
            transform: `translate(${startX + Math.sin(life * 0.1 + i) * 8}px, ${startY - drift}px) scale(${scale})`,
            boxShadow: isGold ? `0 0 12px ${color}` : isPrimary ? `0 0 8px ${color}` : undefined,
          }} />
        );
      })}

      {/* Shockwave effects */}
      <Shockwave trigger={5} color={colors.primary} />
      <Shockwave trigger={10} color={colors.budgieYellow} />

      {/* Lens flare */}
      <LensFlare delay={12} />

      {/* Logo with multi-layer glow */}
      <div style={{
        transform: `scale(${logoScale * logoPulse}) rotate(${logoRotate}deg) translateY(${logoFloat}px)`,
        marginBottom: 20, position: "relative",
      }}>
        {/* Outer pulse ring */}
        <div style={{
          position: "absolute", inset: -50, borderRadius: "50%",
          background: `radial-gradient(circle,
            rgba(255,213,79,${0.2 + Math.sin(frame * 0.08) * 0.1}) 0%,
            rgba(20,241,149,${0.1 + Math.sin(frame * 0.06) * 0.05}) 35%,
            transparent 60%)`,
          filter: "blur(30px)",
          transform: `scale(${1 + Math.sin(frame * 0.05) * 0.08})`,
        }} />
        {/* Rotating accent ring */}
        <div style={{
          position: "absolute", inset: -12, borderRadius: "26%",
          border: `2px solid rgba(255,213,79,${0.12 + Math.sin(frame * 0.12) * 0.08})`,
          transform: `rotate(${frame * 0.4}deg)`,
        }} />
        {/* Second rotating ring (opposite) */}
        <div style={{
          position: "absolute", inset: -20, borderRadius: "50%",
          border: `1px solid rgba(20,241,149,${0.08 + Math.sin(frame * 0.09) * 0.06})`,
          transform: `rotate(${-frame * 0.25}deg)`,
        }} />
        <BudgieIcon size={190} animated />
      </div>

      {/* Title — letter-by-letter with color highlight */}
      <div style={{ display: "flex", justifyContent: "center", marginBottom: 6, fontFamily: fonts.title }}>
        {titleText.split("").map((char, i) => {
          const charDelay = titleStart + i * 1.5;
          const charSpring = spring({
            frame: Math.max(0, frame - charDelay),
            fps,
            config: springPresets.elastic,
          });
          const y = interpolate(charSpring, [0, 1], [60, 0]);
          const rotate = interpolate(charSpring, [0, 0.5, 1], [25, -5, 0]);

          // Color highlight wave
          const highlightWave = Math.sin((frame - i * 2) * 0.08);
          const isHighlighted = highlightWave > 0.7 && frame > titleStart + titleText.length * 1.5 + 10;
          const textColor = isHighlighted ? colors.primary : colors.textOnDark;

          return (
            <span key={i} style={{
              fontSize: 70, fontWeight: 900, display: "inline-block",
              color: textColor,
              transform: `translateY(${y}px) rotate(${rotate}deg)`,
              opacity: charSpring,
              textShadow: `0 0 40px ${colors.primary}40, 0 6px 20px rgba(0,0,0,0.5)`,
              letterSpacing: i === 6 || i === 14 ? 2 : -1.5,
              transition: "color 0.15s",
            }}>
              {char}
            </span>
          );
        })}
      </div>

      {/* Animated underline */}
      <div style={{
        width: interpolate(subtitleProgress, [0, 1], [0, 400]),
        height: 3, borderRadius: 2,
        background: `linear-gradient(90deg, transparent, ${colors.primary}, ${colors.budgieYellow}, transparent)`,
        marginBottom: 12, opacity: subtitleProgress,
        boxShadow: `0 0 15px ${colors.primary}60`,
      }} />

      {/* Subtitle */}
      <div style={{
        opacity: subtitleProgress,
        transform: `translateY(${interpolate(subtitleProgress, [0, 1], [12, 0])}px)`,
        fontFamily: fonts.title,
      }}>
        <p style={{
          fontSize: 24, color: colors.primary, margin: 0,
          fontWeight: 700, letterSpacing: 10, textTransform: "uppercase",
          textShadow: `0 0 30px ${colors.primary}50`,
        }}>
          Profesyonel Kuş Takibi
        </p>
      </div>

      {/* Feature badge pills */}
      <div style={{ marginTop: 34, fontFamily: fonts.body, display: "flex", gap: 12 }}>
        {badges.map((badge, i) => {
          const badgeSpring = spring({
            frame: Math.max(0, frame - 68 - i * 4),
            fps, config: springPresets.pop,
          });
          const floatY = badgeSpring === 1 ? Math.sin((frame - 80) * 0.06 + i * 1.2) * 3 : 0;
          return (
            <div key={i} style={{
              transform: `scale(${badgeSpring}) translateY(${interpolate(badgeSpring, [0, 1], [15, 0]) + floatY}px)`,
              opacity: badgeSpring,
              display: "flex", alignItems: "center", gap: 8,
              background: "rgba(255,255,255,0.06)",
              padding: "8px 18px", borderRadius: 100,
              border: "1px solid rgba(255,255,255,0.1)",
              backdropFilter: "blur(10px)",
            }}>
              <span style={{ fontSize: 14 }}>{badge.icon}</span>
              <span style={{ fontSize: 13, color: "rgba(255,255,255,0.75)", fontWeight: 600, letterSpacing: 1 }}>
                {badge.label}
              </span>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
