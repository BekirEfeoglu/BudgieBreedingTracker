import React from "react";
import {
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, springPresets } from "../theme";

interface FeatureCardProps {
  emoji: string;
  title: string;
  description: string;
  delay: number;
  index: number;
  accentColor: string;
}

export const FeatureCard: React.FC<FeatureCardProps> = ({
  emoji,
  title,
  description,
  delay,
  index,
  accentColor,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const adjustedFrame = Math.max(0, frame - delay);

  const slideIn = spring({
    frame: adjustedFrame,
    fps,
    config: springPresets.snappy,
  });

  const x = interpolate(slideIn, [0, 1], [80, 0]);
  const y = interpolate(slideIn, [0, 1], [30, 0]);
  const opacity = interpolate(adjustedFrame, [0, 8], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Subtle floating animation after entrance
  const floatY = adjustedFrame > 20
    ? Math.sin((adjustedFrame - 20) * 0.06 + index) * 3
    : 0;

  // Icon pulse
  const iconPulse = adjustedFrame > 15
    ? 1 + Math.sin((adjustedFrame - 15) * 0.1 + index * 0.5) * 0.05
    : slideIn;

  return (
    <div
      style={{
        opacity,
        transform: `translate(${x}px, ${y + floatY}px)`,
        display: "flex",
        alignItems: "center",
        gap: 20,
        backgroundColor: colors.surface,
        borderRadius: 20,
        padding: "22px 28px",
        boxShadow: `0 4px 24px rgba(0,0,0,0.06), 0 1px 4px rgba(0,0,0,0.04)`,
        border: `1.5px solid ${accentColor}25`,
        width: 480,
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Accent left border */}
      <div
        style={{
          position: "absolute",
          left: 0,
          top: "15%",
          bottom: "15%",
          width: 3,
          backgroundColor: accentColor,
          borderRadius: 2,
        }}
      />

      {/* Icon container */}
      <div
        style={{
          width: 60,
          height: 60,
          borderRadius: 16,
          background: `linear-gradient(135deg, ${accentColor}18 0%, ${accentColor}08 100%)`,
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          fontSize: 30,
          flexShrink: 0,
          transform: `scale(${iconPulse})`,
          border: `1px solid ${accentColor}20`,
        }}
      >
        {emoji}
      </div>

      {/* Text */}
      <div style={{ flex: 1 }}>
        <h3
          style={{
            fontSize: 20,
            fontWeight: 700,
            color: colors.textPrimary,
            margin: 0,
            lineHeight: 1.2,
          }}
        >
          {title}
        </h3>
        <p
          style={{
            fontSize: 14,
            color: colors.textSecondary,
            margin: "4px 0 0",
            lineHeight: 1.4,
          }}
        >
          {description}
        </p>
      </div>
    </div>
  );
};
