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

// ─── Confetti particle ──────────────────────────────────────
const ConfettiBurst: React.FC<{ trigger: number }> = ({ trigger }) => {
  const frame = useCurrentFrame();
  const elapsed = frame - trigger;
  if (elapsed < 0 || elapsed > 60) return null;

  return (
    <>
      {[...Array(30)].map((_, i) => {
        const angle = seededRandom(i + 900) * Math.PI * 2;
        const speed = 2 + seededRandom(i + 910) * 5;
        const dist = elapsed * speed;
        const x = Math.cos(angle) * dist;
        const y = Math.sin(angle) * dist + elapsed * elapsed * 0.05; // gravity
        const size = 4 + seededRandom(i + 920) * 6;
        const rotation = elapsed * (5 + seededRandom(i + 930) * 10);
        const opacity = interpolate(elapsed, [0, 10, 50, 60], [0, 1, 0.8, 0]);
        const colorChoices = [colors.primary, colors.accent, colors.budgieYellow, colors.budgieBlue, colors.heartRed];
        const color = colorChoices[i % colorChoices.length];
        return (
          <div key={i} style={{
            position: "absolute", left: `calc(50% + ${x}px)`, top: `calc(40% + ${y}px)`,
            width: size, height: size * 0.6, borderRadius: 1,
            backgroundColor: color, opacity,
            transform: `rotate(${rotation}deg)`,
          }} />
        );
      })}
    </>
  );
};

export const OutroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Logo
  const logoScale = spring({ frame, fps, config: springPresets.bouncy });
  const logoFloat = frame > 20 ? Math.sin((frame - 20) * 0.04) * 3 : 0;

  // Title
  const titleOpacity = interpolate(frame, [10, 24], [0, 1], { extrapolateRight: "clamp" });
  const titleY = spring({ frame: Math.max(0, frame - 10), fps, config: springPresets.smooth });

  // CTA
  const ctaScale = spring({ frame: Math.max(0, frame - 32), fps, config: springPresets.bouncy });
  const ctaPulse = frame > 50 ? 1 + Math.sin((frame - 50) * 0.12) * 0.035 : 1;

  // CTA glow rotation
  const ctaGlowAngle = frame * 1.5;

  // Platform badges
  const badgeScale = spring({ frame: Math.max(0, frame - 45), fps, config: springPresets.smooth });

  // Bottom tagline
  const taglineOpacity = interpolate(frame, [60, 80], [0, 1], { extrapolateRight: "clamp" });

  const features = ["Offline-First", "3 Dil Desteği", "AES-256", "27 Mutasyon", "Soy Ağacı"];

  return (
    <AbsoluteFill style={{
      background: `radial-gradient(ellipse at 50% 40%, ${colors.gradient.mid}25 0%, ${colors.background} 55%)`,
      justifyContent: "center", alignItems: "center", overflow: "hidden",
    }}>
      {/* Animated gradient background */}
      <div style={{
        position: "absolute", width: 1100, height: 1100, borderRadius: "50%",
        background: `conic-gradient(from ${ctaGlowAngle}deg, ${colors.primary}08, ${colors.accent}08, ${colors.budgieYellow}05, ${colors.primary}08)`,
        filter: "blur(80px)",
        transform: `scale(${1 + Math.sin(frame * 0.025) * 0.1})`,
      }} />

      {/* Multi-ring orbiting particles */}
      {[...Array(28)].map((_, i) => {
        const ring = i < 14 ? 0 : 1;
        const ringRadius = ring === 0 ? 300 : 420;
        const angle = ((i % 14) / 14) * Math.PI * 2 + frame * (ring === 0 ? 0.03 : -0.02);
        const x = Math.cos(angle) * ringRadius;
        const y = Math.sin(angle) * ringRadius * 0.3;
        const size = 2 + (i % 4);
        const colorIdx = i % 3;
        const c = [colors.primary, colors.accent, colors.budgieYellow][colorIdx];
        return (
          <div key={i} style={{
            position: "absolute", width: size, height: size, borderRadius: "50%",
            backgroundColor: c, opacity: 0.45,
            transform: `translate(${x}px, ${y}px)`,
            boxShadow: `0 0 ${size * 3}px ${c}80`,
          }} />
        );
      })}

      {/* Confetti burst */}
      <ConfettiBurst trigger={35} />

      {/* Logo with glow */}
      <div style={{
        transform: `scale(${logoScale}) translateY(${logoFloat}px)`,
        marginBottom: 22, position: "relative",
      }}>
        <div style={{
          position: "absolute", inset: -40, borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.primary}20 0%, ${colors.accent}08 40%, transparent 60%)`,
          filter: "blur(25px)",
          transform: `scale(${1 + Math.sin(frame * 0.06) * 0.08})`,
        }} />
        {/* Spinning accent ring */}
        <div style={{
          position: "absolute", inset: -15, borderRadius: "50%",
          border: `1.5px solid rgba(20,241,149,${0.1 + Math.sin(frame * 0.1) * 0.06})`,
          transform: `rotate(${frame * 0.5}deg)`,
        }} />
        <BudgieIcon size={145} animated />
      </div>

      {/* App name — with gradient text effect */}
      <div style={{
        opacity: titleOpacity,
        transform: `translateY(${interpolate(titleY, [0, 1], [20, 0])}px)`,
        fontFamily: fonts.title,
      }}>
        <h1 style={{
          fontSize: 60, fontWeight: 900, margin: 0, letterSpacing: -2,
          background: `linear-gradient(135deg, ${colors.textOnDark} 0%, ${colors.primary} 50%, ${colors.textOnDark} 100%)`,
          backgroundSize: "200% 200%",
          backgroundPosition: `${50 + Math.sin(frame * 0.05) * 30}% 50%`,
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          filter: `drop-shadow(0 0 30px ${colors.primary}30)`,
        }}>
          BudgieBreedingTracker
        </h1>
      </div>

      {/* Tagline */}
      <div style={{ opacity: titleOpacity, marginTop: 2, fontFamily: fonts.title }}>
        <p style={{
          fontSize: 19, color: colors.primary, margin: 0,
          fontWeight: 700, letterSpacing: 7, textTransform: "uppercase",
          textShadow: `0 0 20px ${colors.primary}40`,
        }}>
          Profesyonel Kuş Takibi
        </p>
      </div>

      {/* Feature tags */}
      <div style={{
        marginTop: 24, width: 700,
        opacity: interpolate(frame, [22, 35], [0, 1], { extrapolateRight: "clamp" }),
      }}>
        <div style={{ display: "flex", gap: 9, justifyContent: "center", flexWrap: "wrap", fontFamily: fonts.body }}>
          {features.map((feat, i) => {
            const s = spring({ frame: Math.max(0, frame - 25 - i * 2.5), fps, config: springPresets.pop });
            const floatY = s === 1 ? Math.sin((frame - 35) * 0.06 + i * 1.5) * 2 : 0;
            return (
              <div key={i} style={{
                transform: `scale(${s}) translateY(${floatY}px)`, opacity: s,
                padding: "5px 14px", borderRadius: 18,
                backgroundColor: "rgba(255,255,255,0.05)",
                border: "1px solid rgba(255,255,255,0.1)",
                fontSize: 12, fontWeight: 600, color: "rgba(255,255,255,0.55)",
              }}>{feat}</div>
            );
          })}
        </div>
      </div>

      {/* CTA Button with animated gradient border */}
      <div style={{
        transform: `scale(${ctaScale * ctaPulse})`, marginTop: 30,
        position: "relative", fontFamily: fonts.title,
      }}>
        {/* Animated glow ring */}
        <div style={{
          position: "absolute", inset: -4, borderRadius: 100,
          background: `conic-gradient(from ${ctaGlowAngle}deg, ${colors.accent}, ${colors.primary}, ${colors.budgieYellow}, ${colors.accent})`,
          filter: "blur(1px)", opacity: ctaScale,
        }} />
        {/* Button background (covers the conic gradient except border) */}
        <div style={{
          position: "absolute", inset: -1, borderRadius: 100,
          background: `linear-gradient(135deg, ${colors.accent}, ${colors.accentDark})`,
        }} />
        <div style={{
          position: "relative",
          color: "#FFF", padding: "18px 52px", borderRadius: 100,
          fontSize: 24, fontWeight: 900,
          display: "flex", alignItems: "center", gap: 12,
          textShadow: "0 1px 3px rgba(0,0,0,0.3)",
        }}>
          <span>Hemen İndirin</span>
          <span style={{
            fontSize: 20,
            transform: `translateX(${Math.sin(frame * 0.15) * 3}px)`,
          }}>→</span>
        </div>
      </div>

      {/* Platform badges */}
      <div style={{
        display: "flex", gap: 14, marginTop: 28,
        transform: `scale(${badgeScale})`, opacity: badgeScale, fontFamily: fonts.body,
      }}>
        {[
          { name: "App Store", icon: "🍎", sub: "Download on the" },
          { name: "Google Play", icon: "▶️", sub: "GET IT ON" },
        ].map((platform, i) => {
          const floatY = badgeScale === 1 ? Math.sin((frame - 55) * 0.05 + i * 2) * 2 : 0;
          return (
            <div key={platform.name} style={{
              display: "flex", alignItems: "center", gap: 9,
              backgroundColor: "rgba(255,255,255,0.06)",
              border: "1px solid rgba(255,255,255,0.12)",
              borderRadius: 13, padding: "9px 20px",
              transform: `translateY(${floatY}px)`,
            }}>
              <span style={{ fontSize: 17 }}>{platform.icon}</span>
              <div>
                <div style={{ fontSize: 8, color: "rgba(255,255,255,0.35)", fontWeight: 500 }}>{platform.sub}</div>
                <span style={{ color: "rgba(255,255,255,0.85)", fontSize: 14, fontWeight: 700 }}>{platform.name}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Footer */}
      <div style={{ position: "absolute", bottom: 32, opacity: taglineOpacity, textAlign: "center", fontFamily: fonts.body }}>
        <p style={{ fontSize: 12, color: "rgba(255,255,255,0.2)", margin: 0, letterSpacing: 3, fontWeight: 600 }}>
          FLUTTER  ·  SUPABASE  ·  OFFLINE-FIRST  ·  AES-256
        </p>
      </div>
    </AbsoluteFill>
  );
};
