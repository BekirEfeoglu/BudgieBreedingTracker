import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, springPresets } from "../theme";

interface CircularStatProps {
  value: number;
  suffix: string;
  label: string;
  delay: number;
  color: string;
  size: number;
}

const CircularStat: React.FC<CircularStatProps> = ({
  value, suffix, label, delay, color, size,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const adjustedFrame = Math.max(0, frame - delay);

  const scale = spring({
    frame: adjustedFrame,
    fps,
    config: springPresets.bouncy,
  });

  const progress = interpolate(adjustedFrame, [0, 40], [0, 1], {
    extrapolateRight: "clamp",
  });

  const displayValue = Math.round(value * progress);

  // SVG circle progress
  const radius = (size - 12) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - progress * 0.75);

  // Glow pulse
  const glowIntensity = adjustedFrame > 40
    ? 0.3 + Math.sin((adjustedFrame - 40) * 0.08) * 0.1
    : progress * 0.3;

  return (
    <div
      style={{
        transform: `scale(${scale})`,
        textAlign: "center",
        position: "relative",
      }}
    >
      {/* Glow background */}
      <div style={{
        position: "absolute",
        inset: -20,
        borderRadius: "50%",
        background: `radial-gradient(circle, ${color}${Math.round(glowIntensity * 255).toString(16).padStart(2, "0")} 0%, transparent 60%)`,
        filter: "blur(15px)",
      }} />

      <svg width={size} height={size} style={{ position: "relative" }}>
        {/* Background track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="rgba(255,255,255,0.08)"
          strokeWidth={6}
        />
        {/* Progress arc */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={6}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          transform={`rotate(-90, ${size / 2}, ${size / 2})`}
          style={{ filter: `drop-shadow(0 0 8px ${color}60)` }}
        />
      </svg>

      {/* Number overlay */}
      <div style={{
        position: "absolute",
        top: 0,
        left: 0,
        width: size,
        height: size,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "center",
      }}>
        <div style={{
          fontSize: size * 0.3,
          fontWeight: 900,
          color,
          lineHeight: 1,
          textShadow: `0 0 20px ${color}40`,
        }}>
          {displayValue}{suffix}
        </div>
        <div style={{
          fontSize: 13,
          color: "rgba(255,255,255,0.6)",
          marginTop: 6,
          fontWeight: 500,
          textTransform: "uppercase",
          letterSpacing: 2,
        }}>
          {label}
        </div>
      </div>
    </div>
  );
};

const stats = [
  { value: 18, suffix: "", label: "Veritabani", color: colors.budgieYellow },
  { value: 75, suffix: "", label: "Ozel Ikon", color: colors.budgieGreen },
  { value: 46, suffix: "", label: "Sayfa", color: colors.budgieBlue },
  { value: 909, suffix: "", label: "Ceviri", color: colors.accent },
];

export const StatsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const bgOpacity = interpolate(frame, [0, 10], [0, 1], {
    extrapolateRight: "clamp",
  });

  const titleSpring = spring({ frame, fps, config: springPresets.smooth });

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, #0A2E0F 0%, ${colors.gradient.start} 40%, #0D3311 100%)`,
        justifyContent: "center",
        alignItems: "center",
        opacity: bgOpacity,
        overflow: "hidden",
      }}
    >
      {/* Animated background grid */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `
          radial-gradient(rgba(255,255,255,0.03) 1px, transparent 1px)
        `,
        backgroundSize: "40px 40px",
        transform: `translateY(${(frame * 0.3) % 40}px)`,
      }} />

      {/* Title */}
      <div style={{
        position: "absolute", top: 80, textAlign: "center",
        opacity: titleSpring,
        transform: `translateY(${interpolate(titleSpring, [0, 1], [-20, 0])}px)`,
      }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: colors.accent, letterSpacing: 3, textTransform: "uppercase", marginBottom: 8 }}>
          Rakamlarla
        </div>
        <h2 style={{ fontSize: 44, fontWeight: 800, color: colors.textOnDark, margin: 0 }}>
          Proje Boyutu
        </h2>
      </div>

      {/* Stats circles */}
      <div
        style={{
          display: "flex",
          gap: 60,
          justifyContent: "center",
          alignItems: "center",
          marginTop: 40,
        }}
      >
        {stats.map((stat, i) => (
          <CircularStat
            key={i}
            value={stat.value}
            suffix={stat.suffix}
            label={stat.label}
            delay={8 + i * 10}
            color={stat.color}
            size={180}
          />
        ))}
      </div>
    </AbsoluteFill>
  );
};
