import React from "react";
import {
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets } from "../theme";

interface FeatureCardProps {
  emoji: string;
  title: string;
  description: string;
  delay: number;
  index: number;
  accentColor: string;
}

export const FeatureCard: React.FC<FeatureCardProps> = ({
  emoji, title, description, delay, index, accentColor,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const adjustedFrame = Math.max(0, frame - delay);

  const slideIn = spring({ frame: adjustedFrame, fps, config: springPresets.elastic });

  // Staggered entrance from alternating sides
  const fromLeft = index % 2 === 0;
  const x = interpolate(slideIn, [0, 1], [fromLeft ? -60 : 60, 0]);
  const y = interpolate(slideIn, [0, 1], [25, 0]);
  const opacity = interpolate(adjustedFrame, [0, 8], [0, 1], { extrapolateRight: "clamp" });

  // Continuous float after entrance
  const floatY = adjustedFrame > 20 ? Math.sin((adjustedFrame - 20) * 0.04 + index * 0.8) * 3 : 0;

  // Shimmer border animation
  const shimmerPos = ((adjustedFrame * 3 + index * 50) % 300) - 50;

  // Icon bounce
  const iconBounce = adjustedFrame > 15
    ? 1 + Math.sin((adjustedFrame - 15) * 0.1 + index) * 0.06
    : interpolate(slideIn, [0, 0.8, 1], [0.6, 1.15, 1]);

  // Accent glow intensity
  const glowIntensity = 0.3 + Math.sin(adjustedFrame * 0.06 + index * 1.5) * 0.15;

  return (
    <div
      style={{
        opacity,
        transform: `translate(${x}px, ${y + floatY}px)`,
        display: "flex",
        alignItems: "center",
        gap: 22,
        backgroundColor: "rgba(255,255,255,0.03)",
        borderRadius: 24,
        padding: "24px 30px",
        boxShadow: `0 10px 40px rgba(0,0,0,0.25), inset 0 1px 0 rgba(255,255,255,0.05)`,
        border: `1px solid rgba(255,255,255,0.08)`,
        backdropFilter: "blur(12px)",
        width: 460,
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Shimmer sweep */}
      <div style={{
        position: "absolute", top: 0, bottom: 0,
        left: `${shimmerPos}%`, width: "20%",
        background: `linear-gradient(90deg, transparent, ${accentColor}08, transparent)`,
        transform: "skewX(-20deg)",
        pointerEvents: "none",
      }} />

      {/* Left accent bar with glow */}
      <div style={{
        position: "absolute", left: 0, top: 0, bottom: 0, width: 4,
        background: `linear-gradient(to bottom, ${accentColor}, ${accentColor}40, transparent)`,
        boxShadow: `0 0 20px ${accentColor}${Math.round(glowIntensity * 255).toString(16).padStart(2, "0")}`,
      }} />

      {/* Corner accent glow */}
      <div style={{
        position: "absolute", top: -20, left: -20, width: 80, height: 80,
        background: `radial-gradient(circle, ${accentColor}15 0%, transparent 70%)`,
        filter: "blur(10px)",
      }} />

      {/* Animated icon container */}
      <div style={{
        width: 64, height: 64, borderRadius: 18,
        background: `linear-gradient(135deg, ${accentColor}15, rgba(255,255,255,0.03))`,
        display: "flex", justifyContent: "center", alignItems: "center",
        fontSize: 32, flexShrink: 0,
        border: `1px solid ${accentColor}20`,
        transform: `scale(${iconBounce})`,
        boxShadow: `0 0 15px ${accentColor}15`,
      }}>
        {emoji}
      </div>

      {/* Text */}
      <div style={{ flex: 1, fontFamily: fonts.body }}>
        <h3 style={{
          fontSize: 22, fontWeight: 800, color: colors.textOnDark,
          margin: 0, fontFamily: fonts.title, letterSpacing: -0.5,
        }}>
          {title}
        </h3>
        <p style={{
          fontSize: 15, color: "rgba(255,255,255,0.5)",
          margin: "6px 0 0", lineHeight: 1.5, fontWeight: 400,
        }}>
          {description}
        </p>
      </div>
    </div>
  );
};
