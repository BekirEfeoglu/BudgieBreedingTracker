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

// ─── Confetti particle with enhanced physics ────────────────
const ConfettiBurst: React.FC<{ trigger: number }> = ({ trigger }) => {
  const frame = useCurrentFrame();
  const elapsed = frame - trigger;
  if (elapsed < 0 || elapsed > 65) return null;
  const progress = elapsed / 65;

  return (
    <>
      {[...Array(45)].map((_, i) => {
        const angle = seededRandom(i + 900) * Math.PI * 2;
        const speed = 3 + seededRandom(i + 910) * 7;
        const dist = elapsed * speed;
        // Gravity pulls downward increasingly
        const x = Math.cos(angle) * dist * 0.95;
        const y = Math.sin(angle) * dist * 0.95 + elapsed * elapsed * 0.085;
        const sizeWidth = 6 + seededRandom(i + 920) * 8;
        const sizeHeight = sizeWidth * 0.55;
        const rotation = elapsed * (7 + seededRandom(i + 930) * 12);
        const opacity = interpolate(progress, [0, 0.15, 0.8, 1], [0, 1, 0.85, 0]);
        const colorChoices = [colors.primary, colors.accent, colors.budgieYellow, colors.budgieBlue, colors.heartRed];
        const color = colorChoices[i % colorChoices.length];
        return (
          <div key={i} style={{
            position: "absolute", left: `calc(50% + ${x}px)`, top: `calc(40% + ${y}px)`,
            width: sizeWidth, height: sizeHeight, borderRadius: 1.5,
            backgroundColor: color, opacity,
            transform: `rotate(${rotation}deg)`,
            pointerEvents: "none", zIndex: 12,
            boxShadow: `0 0 8px ${color}50`,
          }} />
        );
      })}
    </>
  );
};

export const OutroSceneReels: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Logo
  const logoScale = spring({ frame, fps, config: springPresets.bouncy });
  const logoFloat = frame > 20 ? Math.sin((frame - 20) * 0.04) * 4 : 0;

  // Title
  const titleOpacity = interpolate(frame, [10, 24], [0, 1], { extrapolateRight: "clamp" });
  const titleY = spring({ frame: Math.max(0, frame - 10), fps, config: springPresets.smooth });

  // CTA
  const ctaScale = spring({ frame: Math.max(0, frame - 32), fps, config: springPresets.bouncy });
  const ctaPulse = frame > 50 ? 1 + Math.sin((frame - 50) * 0.12) * 0.035 : 1;
  const ctaSwayX = frame > 40 ? Math.sin((frame - 40) * 0.05) * 3 : 0;
  const ctaSwayY = frame > 40 ? Math.cos((frame - 40) * 0.06) * 3 : 0;

  // CTA glow rotation
  const ctaGlowAngle = frame * 1.8;

  // Platform badges
  const badgeScale = spring({ frame: Math.max(0, frame - 45), fps, config: springPresets.smooth });

  // Bottom tagline
  const taglineOpacity = interpolate(frame, [60, 80], [0, 1], { extrapolateRight: "clamp" });

  const features = ["Offline-First", "3 Dil Desteği", "AES-256 Şifreleme", "27+ Mutasyon", "Detaylı Soy Ağacı"];

  return (
    <AbsoluteFill style={{
      background: `radial-gradient(ellipse at 50% 40%, ${colors.gradient.mid}25 0%, ${colors.background} 55%)`,
      justifyContent: "center", alignItems: "center", overflow: "hidden",
    }}>
      {/* Animated gradient background */}
      <div style={{
        position: "absolute", width: 900, height: 900, borderRadius: "50%",
        background: `conic-gradient(from ${ctaGlowAngle}deg, ${colors.primary}08, ${colors.accent}08, ${colors.budgieYellow}05, ${colors.primary}08)`,
        filter: "blur(70px)",
        transform: `scale(${1 + Math.sin(frame * 0.025) * 0.1})`,
      }} />

      {/* Cyber Grid Lines */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `linear-gradient(rgba(255,255,255,0.01) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.01) 1px, transparent 1px)`,
        backgroundSize: "75px 75px",
        transform: `perspective(500px) rotateX(65deg) translateY(${frame * 0.4}px)`,
        opacity: 0.25,
      }} />

      {/* Multi-ring orbiting particles (Narrower & taller for vertical layout) */}
      {[...Array(30)].map((_, i) => {
        const ring = i < 15 ? 0 : 1;
        const ringRadius = ring === 0 ? 210 : 310;
        const angle = ((i % 15) / 15) * Math.PI * 2 + frame * (ring === 0 ? 0.035 : -0.025);
        const x = Math.cos(angle) * ringRadius;
        const y = Math.sin(angle) * ringRadius * 0.55;
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
        marginBottom: 26, position: "relative",
      }}>
        <div style={{
          position: "absolute", inset: -35, borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.primary}20 0%, ${colors.accent}08 40%, transparent 60%)`,
          filter: "blur(20px)",
          transform: `scale(${1 + Math.sin(frame * 0.06) * 0.08})`,
        }} />
        {/* Spinning accent ring */}
        <div style={{
          position: "absolute", inset: -12, borderRadius: "50%",
          border: `1.5px solid rgba(20,241,149,${0.12 + Math.sin(frame * 0.1) * 0.06})`,
          transform: `rotate(${frame * 0.5}deg)`,
        }} />
        <BudgieIcon size={130} animated />
      </div>

      {/* App name — with gradient text effect */}
      <div style={{
        opacity: titleOpacity,
        transform: `translateY(${interpolate(titleY, [0, 1], [20, 0])}px)`,
        fontFamily: fonts.title,
        textAlign: "center",
      }}>
        <h1 style={{
          fontSize: 46, fontWeight: 900, margin: 0, letterSpacing: -1.8,
          background: `linear-gradient(135deg, ${colors.textOnDark} 0%, ${colors.primary} 50%, ${colors.textOnDark} 100%)`,
          backgroundSize: "200% 200%",
          backgroundPosition: `${50 + Math.sin(frame * 0.05) * 30}% 50%`,
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          filter: `drop-shadow(0 0 25px ${colors.primary}30)`,
        }}>
          BudgieBreedingTracker
        </h1>
      </div>

      {/* Tagline */}
      <div style={{ opacity: titleOpacity, marginTop: 4, fontFamily: fonts.title, textAlign: "center" }}>
        <p style={{
          fontSize: 16, color: colors.primary, margin: 0,
          fontWeight: 700, letterSpacing: 6, textTransform: "uppercase",
          textShadow: `0 0 15px ${colors.primary}35`,
        }}>
          Profesyonel Kuş Takibi
        </p>
      </div>

      {/* Feature tags */}
      <div style={{
        marginTop: 35, width: 600,
        opacity: interpolate(frame, [22, 35], [0, 1], { extrapolateRight: "clamp" }),
      }}>
        <div style={{ display: "flex", gap: 8, justifyContent: "center", flexWrap: "wrap", fontFamily: fonts.body }}>
          {features.map((feat, i) => {
            const s = spring({ frame: Math.max(0, frame - 25 - i * 2.5), fps, config: springPresets.pop });
            const floatY = s === 1 ? Math.sin((frame - 35) * 0.06 + i * 1.5) * 2 : 0;
            return (
              <div key={i} style={{
                transform: `scale(${s}) translateY(${floatY}px)`, opacity: s,
                padding: "6px 14px", borderRadius: 18,
                backgroundColor: "rgba(255,255,255,0.05)",
                border: "1px solid rgba(255,255,255,0.08)",
                fontSize: 12, fontWeight: 600, color: "rgba(255,255,255,0.6)",
                boxShadow: "0 4px 15px rgba(0,0,0,0.1)",
              }}>{feat}</div>
            );
          })}
        </div>
      </div>

      {/* CTA Button with animated gradient border & physical hover pulsate */}
      <div style={{
        transform: `scale(${ctaScale * ctaPulse}) translate(${ctaSwayX}px, ${ctaSwayY}px)`,
        marginTop: 45,
        position: "relative", fontFamily: fonts.title,
      }}>
        {/* Animated glow ring */}
        <div style={{
          position: "absolute", inset: -4, borderRadius: 100,
          background: `conic-gradient(from ${ctaGlowAngle}deg, ${colors.accent}, ${colors.primary}, ${colors.budgieYellow}, ${colors.accent})`,
          filter: "blur(1.5px)", opacity: ctaScale,
        }} />
        {/* Button background */}
        <div style={{
          position: "absolute", inset: -1, borderRadius: 100,
          background: `linear-gradient(135deg, ${colors.accent}, ${colors.accentDark})`,
        }} />
        <div style={{
          position: "relative",
          color: "#FFF", padding: "18px 52px", borderRadius: 100,
          fontSize: 22, fontWeight: 900,
          display: "flex", alignItems: "center", gap: 10,
          textShadow: "0 1px 3px rgba(0,0,0,0.35)",
          cursor: "pointer",
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
        display: "flex", gap: 12, marginTop: 45,
        transform: `scale(${badgeScale})`, opacity: badgeScale, fontFamily: fonts.body,
        justifyContent: "center", width: 500,
      }}>
        {[
          { name: "App Store", icon: "🍎", sub: "Download on the" },
          { name: "Google Play", icon: "▶️", sub: "GET IT ON" },
        ].map((platform, i) => {
          const floatY = badgeScale === 1 ? Math.sin((frame - 55) * 0.05 + i * 2) * 2 : 0;
          return (
            <div key={platform.name} style={{
              display: "flex", alignItems: "center", gap: 8,
              backgroundColor: "rgba(255,255,255,0.05)",
              border: "1px solid rgba(255,255,255,0.1)",
              borderRadius: 14, padding: "8px 16px",
              transform: `translateY(${floatY}px)`,
              width: 170,
              boxShadow: "0 6px 20px rgba(0,0,0,0.15)",
            }}>
              <span style={{ fontSize: 18 }}>{platform.icon}</span>
              <div>
                <div style={{ fontSize: 8, color: "rgba(255,255,255,0.35)", fontWeight: 500 }}>{platform.sub}</div>
                <span style={{ color: "rgba(255,255,255,0.8)", fontSize: 13, fontWeight: 700 }}>{platform.name}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Footer */}
      <div style={{ position: "absolute", bottom: 80, opacity: taglineOpacity, textAlign: "center", fontFamily: fonts.body }}>
        <p style={{ fontSize: 11, color: "rgba(255,255,255,0.2)", margin: 0, letterSpacing: 2, fontWeight: 600 }}>
          FLUTTER  ·  SUPABASE  ·  OFFLINE-FIRST  ·  AES-256
        </p>
      </div>
    </AbsoluteFill>
  );
};
