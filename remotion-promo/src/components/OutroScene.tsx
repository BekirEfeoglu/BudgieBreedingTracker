import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, springPresets } from "../theme";
import { BudgieIcon } from "./BudgieIcon";

export const OutroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Logo
  const logoScale = spring({ frame, fps, config: springPresets.bouncy });

  // Title
  const titleOpacity = interpolate(frame, [15, 30], [0, 1], {
    extrapolateRight: "clamp",
  });
  const titleY = spring({
    frame: Math.max(0, frame - 15),
    fps,
    config: springPresets.smooth,
  });

  // CTA button
  const ctaScale = spring({
    frame: Math.max(0, frame - 30),
    fps,
    config: springPresets.bouncy,
  });
  const ctaPulse = frame > 45
    ? 1 + Math.sin((frame - 45) * 0.08) * 0.03
    : 1;

  // CTA glow
  const ctaGlow = frame > 45
    ? 0.3 + Math.sin((frame - 45) * 0.1) * 0.15
    : 0;

  // Platform badges
  const badgeScale = spring({
    frame: Math.max(0, frame - 45),
    fps,
    config: springPresets.snappy,
  });

  // Bottom tagline
  const taglineOpacity = interpolate(frame, [55, 70], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Background gradient rotation
  const gradientAngle = interpolate(frame, [0, 100], [135, 160]);

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(${gradientAngle}deg, #0A2E0F 0%, ${colors.gradient.start} 30%, ${colors.gradient.mid} 60%, ${colors.gradient.end} 100%)`,
        justifyContent: "center",
        alignItems: "center",
        overflow: "hidden",
      }}
    >
      {/* Radial glow */}
      <div style={{
        position: "absolute",
        width: 800, height: 800,
        borderRadius: "50%",
        background: `radial-gradient(circle, rgba(76,175,80,0.15) 0%, transparent 60%)`,
        filter: "blur(40px)",
      }} />

      {/* Orbiting particles */}
      {[...Array(16)].map((_, i) => {
        const angle = (i / 16) * Math.PI * 2 + frame * 0.015;
        const radius = 300 + Math.sin(frame * 0.03 + i * 0.5) * 30;
        const x = Math.cos(angle) * radius;
        const y = Math.sin(angle) * radius * 0.5;
        const size = 3 + (i % 3);
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              width: size,
              height: size,
              borderRadius: "50%",
              backgroundColor: i % 2 === 0
                ? colors.budgieYellow
                : "rgba(255,255,255,0.25)",
              transform: `translate(${x}px, ${y}px)`,
              boxShadow: i % 2 === 0
                ? `0 0 6px ${colors.budgieYellow}80`
                : "none",
            }}
          />
        );
      })}

      {/* Logo */}
      <div style={{
        transform: `scale(${logoScale})`,
        marginBottom: 20,
        position: "relative",
      }}>
        <div style={{
          position: "absolute", inset: -25, borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.budgieYellow}20 0%, transparent 60%)`,
          filter: "blur(15px)",
        }} />
        <BudgieIcon size={130} />
      </div>

      {/* App name */}
      <div style={{
        opacity: titleOpacity,
        transform: `translateY(${interpolate(titleY, [0, 1], [15, 0])}px)`,
      }}>
        <h1 style={{
          fontSize: 60,
          fontWeight: 900,
          color: colors.textOnDark,
          margin: 0,
          textShadow: "0 4px 30px rgba(0,0,0,0.4)",
          letterSpacing: -1,
        }}>
          BudgieBreeder
        </h1>
      </div>

      {/* Tagline */}
      <div style={{
        opacity: titleOpacity,
        marginTop: 4,
      }}>
        <p style={{
          fontSize: 18, color: colors.primaryLight, margin: 0,
          fontWeight: 400, letterSpacing: 4, textTransform: "uppercase",
        }}>
          Profesyonel Ureme Takibi
        </p>
      </div>

      {/* CTA Button */}
      <div style={{
        transform: `scale(${ctaScale * ctaPulse})`,
        marginTop: 36,
        position: "relative",
      }}>
        {/* Button glow */}
        <div style={{
          position: "absolute", inset: -10,
          borderRadius: 60,
          background: `${colors.accent}`,
          opacity: ctaGlow,
          filter: "blur(20px)",
        }} />
        <div style={{
          background: `linear-gradient(135deg, ${colors.accent}, ${colors.accentDark})`,
          color: colors.textOnPrimary,
          padding: "20px 56px",
          borderRadius: 50,
          fontSize: 24,
          fontWeight: 800,
          boxShadow: `0 8px 32px rgba(255,152,0,0.4)`,
          textAlign: "center",
          letterSpacing: 0.5,
          position: "relative",
        }}>
          Hemen Indirin
        </div>
      </div>

      {/* Platform badges */}
      <div style={{
        display: "flex",
        gap: 16,
        marginTop: 28,
        transform: `scale(${badgeScale})`,
      }}>
        {[
          { name: "Android", icon: "🤖" },
          { name: "iOS", icon: "🍎" },
          { name: "Web", icon: "🌐" },
        ].map((platform, i) => (
          <div
            key={platform.name}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
              backgroundColor: "rgba(255,255,255,0.08)",
              border: "1px solid rgba(255,255,255,0.15)",
              borderRadius: 14,
              padding: "10px 20px",
              backdropFilter: "blur(10px)",
            }}
          >
            <span style={{ fontSize: 16 }}>{platform.icon}</span>
            <span style={{
              color: "rgba(255,255,255,0.85)",
              fontSize: 15,
              fontWeight: 600,
            }}>
              {platform.name}
            </span>
          </div>
        ))}
      </div>

      {/* Bottom tagline */}
      <div style={{
        position: "absolute",
        bottom: 50,
        opacity: taglineOpacity,
        textAlign: "center",
      }}>
        <p style={{
          fontSize: 14,
          color: "rgba(255,255,255,0.35)",
          margin: 0,
          letterSpacing: 2,
        }}>
          Flutter  ·  Supabase  ·  Offline-First  ·  AES-256
        </p>
      </div>
    </AbsoluteFill>
  );
};
