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
  if (elapsed < 0 || elapsed > 45) return null;
  const progress = elapsed / 45;
  const size = progress * 700;
  const opacity = interpolate(progress, [0, 0.15, 1], [0, 0.7, 0]);
  return (
    <div style={{
      position: "absolute", width: size, height: size, borderRadius: "50%",
      border: `3px solid ${color}`, opacity,
      transform: `scale(${1 + progress * 0.45})`,
      boxShadow: `0 0 40px ${color}50, inset 0 0 20px ${color}30`,
      pointerEvents: "none",
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
      width: 600, height: 6,
      background: `linear-gradient(90deg, transparent, ${colors.primary}, ${colors.budgieYellow}, ${colors.accent}, transparent)`,
      opacity: progress * 0.85,
      filter: "blur(2px)",
      transform: `rotate(-12deg) scaleX(${progress})`,
      pointerEvents: "none",
    }} />
  );
};

export const IntroSceneReels: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ── Logo entrance ──
  const logoScale = spring({ frame, fps, config: { ...springPresets.pop, stiffness: 220 } });
  const logoRotate = interpolate(logoScale, [0, 0.5, 1], [-25, 5, 0]);
  const logoPulse = frame > 30 ? 1 + Math.sin((frame - 30) * 0.08) * 0.03 : 1;
  const logoFloat = frame > 40 ? Math.sin((frame - 40) * 0.04) * 4 : 0;

  // ── Title Animation (Split into lines for premium vertical feel) ──
  const title1Start = 15;
  const title2Start = 28;
  const subtitleStart = 45;

  const title1Spring = spring({ frame: Math.max(0, frame - title1Start), fps, config: springPresets.bouncy });
  const title2Spring = spring({ frame: Math.max(0, frame - title2Start), fps, config: springPresets.bouncy });
  const subtitleProgress = spring({ frame: Math.max(0, frame - subtitleStart), fps, config: springPresets.smooth });

  // ── Background ──
  const gradientAngle = interpolate(frame, [0, 200], [135, 165]);
  const bgBrightness = interpolate(frame, [0, 8, 15], [0, 0.3, 1], { extrapolateRight: "clamp" });

  // ── Orbs (Adjusted for vertical screen and neon aesthetics) ──
  const orbData = Array.from({ length: 8 }, (_, i) => ({
    speed: 0.012 + seededRandom(i) * 0.015,
    radius: 180 + seededRandom(i + 10) * 160,
    size: 250 + seededRandom(i + 20) * 200,
    hue: i % 2 === 0 ? 140 : 270, // Primary Green (140) and Accent Purple (270)
  }));

  // ── Badges ──
  const badges = [
    { label: "Offline-First", icon: "📱" },
    { label: "3 Dil Desteği", icon: "🌍" },
    { label: "AES-256 Kripto", icon: "🔐" },
    { label: "27+ Mutasyon", icon: "🧬" },
  ];

  // Dynamic colors
  const pulsingPrimary = `hsla(${140 + Math.sin(frame * 0.06) * 15}, 95%, 55%, 1)`;

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(${gradientAngle}deg, #020704 0%, ${colors.gradient.start} 30%, ${colors.gradient.mid} 65%, ${colors.gradient.end} 100%)`,
        justifyContent: "center",
        alignItems: "center",
        overflow: "hidden",
        opacity: bgBrightness,
      }}
    >
      {/* Animated neon orbs */}
      {orbData.map((orb, i) => {
        const x = Math.sin(frame * orb.speed + i * 1.8) * orb.radius;
        const y = Math.cos(frame * orb.speed * 0.8 + i * 1.3) * (orb.radius * 1.1);
        return (
          <div key={i} style={{
            position: "absolute", width: orb.size, height: orb.size, borderRadius: "50%",
            background: `radial-gradient(circle, hsla(${orb.hue}, 80%, 45%, 0.18) 0%, transparent 70%)`,
            transform: `translate(${x}px, ${y}px)`, filter: "blur(45px)",
          }} />
        );
      })}

      {/* Cyber Grid Plane */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `
          linear-gradient(rgba(20,241,149,0.04) 1.5px, transparent 1.5px),
          linear-gradient(90deg, rgba(20,241,149,0.04) 1.5px, transparent 1.5px)
        `,
        backgroundSize: "45px 45px",
        transform: `perspective(400px) rotateX(72deg) translateY(${-100 + frame * 1.1}px)`,
        transformOrigin: "center top",
        opacity: interpolate(frame, [0, 25], [0, 0.75], { extrapolateRight: "clamp" }),
      }} />

      {/* Moving scanline */}
      <div style={{
        position: "absolute", left: 0, right: 0,
        height: 8,
        background: `linear-gradient(180deg, transparent, ${colors.primary}60, transparent)`,
        opacity: 0.2 + Math.sin(frame * 0.05) * 0.08,
        top: `${(frame * 5.5) % 1920}px`,
        boxShadow: `0 0 25px ${colors.primary}`,
        pointerEvents: "none", zIndex: 5,
      }} />

      {/* Sparkle field */}
      {[...Array(35)].map((_, i) => {
        const life = (frame + i * 13) % 90;
        const startX = (seededRandom(i + 500) * 1100) - 550;
        const startY = (seededRandom(i + 600) * 1900) - 950;
        const opacity = interpolate(life, [0, 10, 60, 90], [0, 0.9, 0.7, 0]);
        const scale = interpolate(life, [0, 10, 90], [0, 1.1, 0.15]);
        const drift = life * 0.85;
        const isGold = i % 5 === 0;
        const isPrimary = i % 7 === 0;
        const color = isGold ? colors.budgieYellow : isPrimary ? pulsingPrimary : "rgba(255,255,255,0.45)";
        return (
          <div key={i} style={{
            position: "absolute", width: isGold ? 5 : 2.5, height: isGold ? 5 : 2.5,
            borderRadius: "50%", backgroundColor: color, opacity,
            transform: `translate(${startX + Math.sin(life * 0.08 + i) * 8}px, ${startY - drift}px) scale(${scale})`,
            boxShadow: isGold ? `0 0 12px ${color}` : isPrimary ? `0 0 8px ${color}` : undefined,
          }} />
        );
      })}

      {/* Shockwave effects */}
      <Shockwave trigger={8} color={pulsingPrimary} />
      <Shockwave trigger={16} color={colors.budgieYellow} />

      {/* Lens flare */}
      <LensFlare delay={14} />

      {/* Logo with multi-layer neon portal glow */}
      <div style={{
        transform: `scale(${logoScale * logoPulse}) rotate(${logoRotate}deg) translateY(${logoFloat}px)`,
        marginBottom: 50, position: "relative", zIndex: 10,
      }}>
        {/* Outer neon pulse portal */}
        <div style={{
          position: "absolute", inset: -55, borderRadius: "50%",
          background: `radial-gradient(circle,
            rgba(255,213,79,${0.25 + Math.sin(frame * 0.08) * 0.12}) 0%,
            rgba(20,241,149,${0.18 + Math.sin(frame * 0.06) * 0.08}) 35%,
            transparent 60%)`,
          filter: "blur(22px)",
          transform: `scale(${1 + Math.sin(frame * 0.05) * 0.09})`,
        }} />
        {/* Rotating accent rings */}
        <div style={{
          position: "absolute", inset: -14, borderRadius: "30%",
          border: `2px solid rgba(255,213,79,${0.2 + Math.sin(frame * 0.12) * 0.1})`,
          boxShadow: `0 0 15px rgba(255,213,79,0.15)`,
          transform: `rotate(${frame * 0.55}deg)`,
        }} />
        <div style={{
          position: "absolute", inset: -24, borderRadius: "50%",
          border: `1.5px solid rgba(20,241,149,${0.15 + Math.sin(frame * 0.09) * 0.08})`,
          boxShadow: `0 0 15px rgba(20,241,149,0.15)`,
          transform: `rotate(${-frame * 0.3}deg)`,
        }} />
        <BudgieIcon size={180} animated />
      </div>

      {/* Title - Line 1: "BUDGIE" */}
      <div style={{
        opacity: title1Spring,
        transform: `scale(${interpolate(title1Spring, [0, 1], [0.7, 1])}) translateY(${interpolate(title1Spring, [0, 1], [30, 0])}px)`,
        fontFamily: fonts.title,
        textAlign: "center",
        zIndex: 10,
      }}>
        <h1 style={{
          fontSize: 74, fontWeight: 900, margin: "0 0 4px", letterSpacing: 2,
          background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.budgieYellow} 100%)`,
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          filter: `drop-shadow(0 0 30px ${colors.primary}50)`,
          textTransform: "uppercase",
        }}>
          BUDGIE
        </h1>
      </div>

      {/* Title - Line 2: "Breeding Tracker" */}
      <div style={{
        opacity: title2Spring,
        transform: `scale(${interpolate(title2Spring, [0, 1], [0.85, 1])}) translateY(${interpolate(title2Spring, [0, 1], [25, 0])}px)`,
        fontFamily: fonts.title,
        textAlign: "center",
        marginBottom: 16,
        zIndex: 10,
      }}>
        <h2 style={{
          fontSize: 34, fontWeight: 800, margin: 0, letterSpacing: -1,
          color: colors.textOnDark,
          filter: "drop-shadow(0 4px 12px rgba(0,0,0,0.6))",
        }}>
          Breeding Tracker
        </h2>
      </div>

      {/* Animated underline */}
      <div style={{
        width: interpolate(subtitleProgress, [0, 1], [0, 360]),
        height: 3, borderRadius: 2,
        background: `linear-gradient(90deg, transparent, ${colors.primary}, ${colors.budgieYellow}, ${colors.accent}, transparent)`,
        marginBottom: 20, opacity: subtitleProgress,
        boxShadow: `0 0 15px ${colors.primary}70`,
        zIndex: 10,
      }} />

      {/* Subtitle */}
      <div style={{
        opacity: subtitleProgress,
        transform: `translateY(${interpolate(subtitleProgress, [0, 1], [10, 0])}px)`,
        fontFamily: fonts.title,
        textAlign: "center",
        zIndex: 10,
      }}>
        <p style={{
          fontSize: 18, color: pulsingPrimary, margin: 0,
          fontWeight: 700, letterSpacing: 8, textTransform: "uppercase",
          textShadow: `0 0 25px ${colors.primary}60`,
        }}>
          Profesyonel Kuş Takibi
        </p>
      </div>

      {/* Feature badge pills (2x2 grid for Reels) */}
      <div style={{
        marginTop: 50,
        fontFamily: fonts.body,
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: 14,
        width: 500,
        padding: "0 20px",
        zIndex: 10,
      }}>
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
              display: "flex", alignItems: "center", gap: 10,
              background: "rgba(255,255,255,0.04)",
              padding: "12px 16px", borderRadius: 20,
              border: "1px solid rgba(255,255,255,0.08)",
              backdropFilter: "blur(12px)",
              boxShadow: `0 8px 25px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.05)`,
            }}>
              <span style={{ fontSize: 18 }}>{badge.icon}</span>
              <span style={{ fontSize: 12.5, color: "rgba(255,255,255,0.85)", fontWeight: 700, letterSpacing: 0.5 }}>
                {badge.label}
              </span>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
