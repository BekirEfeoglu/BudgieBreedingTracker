import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets, seededRandom } from "../theme";

// ─── Spark burst on count complete ──────────────────────────
const SparkBurst: React.FC<{ x: number; y: number; trigger: number; color: string }> = ({ x, y, trigger, color }) => {
  const frame = useCurrentFrame();
  const elapsed = frame - trigger;
  if (elapsed < 0 || elapsed > 25) return null;
  const progress = elapsed / 25;
  return (
    <>
      {[...Array(8)].map((_, i) => {
        const angle = (i / 8) * Math.PI * 2;
        const dist = progress * 40;
        const sx = Math.cos(angle) * dist;
        const sy = Math.sin(angle) * dist;
        return (
          <div key={i} style={{
            position: "absolute", left: x + sx, top: y + sy,
            width: 3, height: 3, borderRadius: "50%",
            backgroundColor: color, opacity: 1 - progress,
            boxShadow: `0 0 6px ${color}`,
          }} />
        );
      })}
    </>
  );
};

interface CircularStatProps {
  value: number;
  suffix: string;
  label: string;
  delay: number;
  color: string;
  size: number;
}

const CircularStat: React.FC<CircularStatProps> = ({ value, suffix, label, delay, color, size }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const adjustedFrame = Math.max(0, frame - delay);

  const scale = spring({ frame: adjustedFrame, fps, config: springPresets.bouncy });
  const progress = interpolate(adjustedFrame, [0, 45], [0, 1], { extrapolateRight: "clamp" });
  const displayValue = Math.round(value * progress);

  const radius = (size - 16) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - progress * 0.8);

  // Pulsing glow
  const glowPulse = adjustedFrame > 45 ? 0.5 + Math.sin((adjustedFrame - 45) * 0.08) * 0.2 : 0.3;

  // Floating animation
  const floatY = adjustedFrame > 30 ? Math.sin((adjustedFrame - 30) * 0.04) * 3 : 0;

  return (
    <div style={{
      transform: `scale(${scale}) translateY(${floatY}px)`,
      textAlign: "center", position: "relative", fontFamily: fonts.body,
    }}>
      {/* Animated glow */}
      <div style={{
        position: "absolute", inset: -35, borderRadius: "50%",
        background: `radial-gradient(circle, ${color}${Math.round(glowPulse * 255).toString(16).padStart(2, "0")} 0%, transparent 65%)`,
        filter: "blur(25px)",
      }} />

      {/* Outer decorative ring */}
      <svg width={size + 20} height={size + 20} style={{ position: "absolute", left: -10, top: -10 }}>
        <circle
          cx={(size + 20) / 2} cy={(size + 20) / 2} r={radius + 12}
          fill="none" stroke={`${color}10`} strokeWidth={1}
          strokeDasharray="4 8"
          transform={`rotate(${frame * 0.3}, ${(size + 20) / 2}, ${(size + 20) / 2})`}
        />
      </svg>

      <svg width={size} height={size} style={{ position: "relative" }}>
        {/* Background track */}
        <circle cx={size / 2} cy={size / 2} r={radius} fill="none"
          stroke="rgba(255,255,255,0.04)" strokeWidth={10} />
        {/* Progress arc */}
        <circle cx={size / 2} cy={size / 2} r={radius} fill="none"
          stroke={color} strokeWidth={10} strokeLinecap="round"
          strokeDasharray={circumference} strokeDashoffset={strokeDashoffset}
          transform={`rotate(-90, ${size / 2}, ${size / 2})`}
          style={{ filter: `drop-shadow(0 0 12px ${color}90)` }}
        />
        {/* Dot at end of arc */}
        {progress > 0.1 && (() => {
          const angle = -90 + progress * 0.8 * 360;
          const rad = (angle * Math.PI) / 180;
          const dotX = size / 2 + Math.cos(rad) * radius;
          const dotY = size / 2 + Math.sin(rad) * radius;
          return (
            <circle cx={dotX} cy={dotY} r={5} fill={color}
              style={{ filter: `drop-shadow(0 0 8px ${color})` }} />
          );
        })()}
      </svg>

      {/* Number overlay */}
      <div style={{
        position: "absolute", top: 0, left: 0, width: size, height: size,
        display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center",
      }}>
        <div style={{
          fontSize: size * 0.26, fontWeight: 900, color: colors.textOnDark,
          lineHeight: 1, fontFamily: fonts.title,
        }}>
          {displayValue}{suffix}
        </div>
        <div style={{
          fontSize: 13, color: "rgba(255,255,255,0.45)", marginTop: 8,
          fontWeight: 600, textTransform: "uppercase", letterSpacing: 2,
        }}>
          {label}
        </div>
      </div>
    </div>
  );
};

const stats = [
  { value: 38,   suffix: "",  label: "DB Tablo",   color: colors.primary },
  { value: 82,   suffix: "",  label: "Özel İkon",  color: colors.accent },
  { value: 52,   suffix: "",  label: "Ekran",      color: colors.budgieBlue },
  { value: 1837, suffix: "",  label: "Çeviri Key", color: colors.budgieYellow },
];

export const StatsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const titleSpring = spring({ frame, fps, config: springPresets.smooth });

  return (
    <AbsoluteFill style={{
      backgroundColor: colors.background,
      justifyContent: "center", alignItems: "center", overflow: "hidden",
    }}>
      {/* Animated grid */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `linear-gradient(rgba(255,255,255,0.018) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.018) 1px, transparent 1px)`,
        backgroundSize: "60px 60px",
        transform: `translateY(${frame * 0.1}px)`, opacity: 0.5,
      }} />

      {/* Connecting lines between stat circles */}
      <svg style={{ position: "absolute", width: "100%", height: "100%", opacity: 0.06 }}>
        {[0, 1, 2].map((i) => {
          const x1 = 310 + i * 330;
          const x2 = x1 + 330;
          const lineP = interpolate(frame, [20 + i * 10, 50 + i * 10], [0, 1], { extrapolateRight: "clamp" });
          return (
            <line key={i} x1={x1} y1={540} x2={x1 + (x2 - x1) * lineP} y2={540}
              stroke={colors.primary} strokeWidth={1} strokeDasharray="4 6" />
          );
        })}
      </svg>

      {/* Background particles */}
      {[...Array(15)].map((_, i) => {
        const x = seededRandom(i + 700) * 1920;
        const speed = 0.2 + seededRandom(i + 710) * 0.3;
        const y = ((frame * speed + seededRandom(i + 720) * 1000) % 1200) - 100;
        return (
          <div key={i} style={{
            position: "absolute", left: x, top: y,
            width: 2, height: 2, borderRadius: "50%",
            backgroundColor: i % 4 === 0 ? colors.primary : "rgba(255,255,255,0.2)",
            opacity: 0.3,
          }} />
        );
      })}

      {/* Title */}
      <div style={{
        position: "absolute", top: 90, textAlign: "center",
        opacity: titleSpring,
        transform: `translateY(${interpolate(titleSpring, [0, 1], [-25, 0])}px)`,
        fontFamily: fonts.title,
      }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 10,
          fontSize: 14, fontWeight: 700, color: colors.accent,
          letterSpacing: 5, textTransform: "uppercase", marginBottom: 12,
        }}>
          <div style={{ width: interpolate(titleSpring, [0, 1], [0, 35]), height: 1, backgroundColor: colors.accent, opacity: 0.5 }} />
          Verilerle
          <div style={{ width: interpolate(titleSpring, [0, 1], [0, 35]), height: 1, backgroundColor: colors.accent, opacity: 0.5 }} />
        </div>
        <h2 style={{ fontSize: 56, fontWeight: 900, color: colors.textOnDark, margin: 0, textShadow: "0 8px 30px rgba(0,0,0,0.4)" }}>
          Proje Ölçeği
        </h2>
      </div>

      {/* Stats circles */}
      <div style={{
        display: "flex", gap: 55, justifyContent: "center", alignItems: "center", marginTop: 50,
        position: "relative",
      }}>
        {stats.map((stat, i) => (
          <React.Fragment key={i}>
            <CircularStat
              value={stat.value} suffix={stat.suffix} label={stat.label}
              delay={8 + i * 10} color={stat.color} size={195}
            />
            {/* Spark burst when counting finishes */}
            <SparkBurst
              x={i * 250 + 97} y={97}
              trigger={8 + i * 10 + 45}
              color={stat.color}
            />
          </React.Fragment>
        ))}
      </div>
    </AbsoluteFill>
  );
};
