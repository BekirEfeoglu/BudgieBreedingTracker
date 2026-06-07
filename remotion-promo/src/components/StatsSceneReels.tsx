import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets, seededRandom } from "../theme";

// ─── Gravity Spark burst on count complete ──────────────────
const SparkBurst: React.FC<{ x: number; y: number; trigger: number; color: string }> = ({ x, y, trigger, color }) => {
  const frame = useCurrentFrame();
  const elapsed = frame - trigger;
  if (elapsed < 0 || elapsed > 30) return null;
  const progress = elapsed / 30;
  return (
    <>
      {[...Array(12)].map((_, i) => {
        const angle = (i / 12) * Math.PI * 2 + seededRandom(i) * 0.5;
        const speed = 1.5 + seededRandom(i + 15) * 2.5;
        const dist = progress * 65 * speed;
        const sx = Math.cos(angle) * dist;
        const sy = Math.sin(angle) * dist + (progress * progress * 20); // Gravity effect
        const opacity = interpolate(progress, [0, 0.7, 1], [1, 0.8, 0]);
        const size = 3.5 - progress * 2;
        const c = i % 2 === 0 ? color : colors.budgieYellow;
        return (
          <div key={i} style={{
            position: "absolute", left: x + sx, top: y + sy,
            width: size, height: size, borderRadius: "50%",
            backgroundColor: c, opacity,
            boxShadow: `0 0 10px ${c}`,
            pointerEvents: "none", zIndex: 10,
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

  const radius = (size - 24) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - progress * 0.8);

  // Pulsing glow
  const glowPulse = adjustedFrame > 45 ? 0.45 + Math.sin((adjustedFrame - 45) * 0.08) * 0.15 : 0.25;

  // Floating animation
  const floatY = adjustedFrame > 30 ? Math.sin((adjustedFrame - 30) * 0.045) * 4 : 0;

  return (
    <div style={{
      transform: `scale(${scale}) translateY(${floatY}px)`,
      textAlign: "center", position: "relative", fontFamily: fonts.body,
      width: size, height: size,
    }}>
      {/* Animated glow */}
      <div style={{
        position: "absolute", inset: -40, borderRadius: "50%",
        background: `radial-gradient(circle, ${color}${Math.round(glowPulse * 255).toString(16).padStart(2, "0")} 0%, transparent 65%)`,
        filter: "blur(30px)",
      }} />

      {/* Outer decorative ring (Clockwise) */}
      <svg width={size + 30} height={size + 30} style={{ position: "absolute", left: -15, top: -15 }}>
        <circle
          cx={(size + 30) / 2} cy={(size + 30) / 2} r={radius + 16}
          fill="none" stroke={`${color}12`} strokeWidth={1}
          strokeDasharray="4 10"
          transform={`rotate(${frame * 0.3}, ${(size + 30) / 2}, ${(size + 30) / 2})`}
        />
        {/* Inner opposite spinning ring (Counter-clockwise) */}
        <circle
          cx={(size + 30) / 2} cy={(size + 30) / 2} r={radius - 12}
          fill="none" stroke={`${color}08`} strokeWidth={1}
          strokeDasharray="2 6"
          transform={`rotate(${-frame * 0.45}, ${(size + 30) / 2}, ${(size + 30) / 2})`}
        />
      </svg>

      <svg width={size} height={size} style={{ position: "relative" }}>
        {/* Background track */}
        <circle cx={size / 2} cy={size / 2} r={radius} fill="none"
          stroke="rgba(255,255,255,0.035)" strokeWidth={12} />
        {/* Progress arc */}
        <circle cx={size / 2} cy={size / 2} r={radius} fill="none"
          stroke={color} strokeWidth={12} strokeLinecap="round"
          strokeDasharray={circumference} strokeDashoffset={strokeDashoffset}
          transform={`rotate(-90, ${size / 2}, ${size / 2})`}
          style={{ filter: `drop-shadow(0 0 16px ${color}90)` }}
        />
        {/* Dot at end of arc */}
        {progress > 0.1 && (() => {
          const angle = -90 + progress * 0.8 * 360;
          const rad = (angle * Math.PI) / 180;
          const dotX = size / 2 + Math.cos(rad) * radius;
          const dotY = size / 2 + Math.sin(rad) * radius;
          return (
            <circle cx={dotX} cy={dotY} r={6} fill={color}
              style={{ filter: `drop-shadow(0 0 10px ${color})` }} />
          );
        })()}
      </svg>

      {/* Number overlay */}
      <div style={{
        position: "absolute", top: 0, left: 0, width: size, height: size,
        display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center",
      }}>
        <div style={{
          fontSize: size * 0.24, fontWeight: 900, color: colors.textOnDark,
          lineHeight: 1, fontFamily: fonts.title,
          filter: "drop-shadow(0 2px 5px rgba(0,0,0,0.5))",
        }}>
          {displayValue}{suffix}
        </div>
        <div style={{
          fontSize: 14, color: "rgba(255,255,255,0.5)", marginTop: 10,
          fontWeight: 700, textTransform: "uppercase", letterSpacing: 2,
        }}>
          {label}
        </div>
      </div>

      {/* Burst when complete */}
      <SparkBurst
        x={size / 2} y={size / 2}
        trigger={delay + 45}
        color={color}
      />
    </div>
  );
};

const stats = [
  { value: 38,   suffix: "",  label: "Drift Tablo", color: colors.primary },
  { value: 82,   suffix: "",  label: "Özel İkon",  color: colors.accent },
  { value: 52,   suffix: "",  label: "Aktif Ekran", color: colors.budgieBlue },
  { value: 1837, suffix: "",  label: "Çeviri Anahtar", color: colors.budgieYellow },
];

export const StatsSceneReels: React.FC = () => {
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
        backgroundImage: `linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px)`,
        backgroundSize: "80px 80px",
        transform: `translateY(${frame * 0.12}px)`, opacity: 0.4,
      }} />

      {/* Grid connecting lines in background (dikey 2x2 grid) */}
      <svg style={{ position: "absolute", width: "100%", height: "100%", opacity: 0.05, overflow: "visible" }}
        viewBox="-540 -960 1080 1920"
      >
        <g transform="translate(0, 100)">
          <line x1={-170} y1={-180} x2={170} y2={-180} stroke={colors.primary} strokeWidth={1.5} strokeDasharray="5 7" />
          <line x1={-170} y1={180} x2={170} y2={180} stroke={colors.primary} strokeWidth={1.5} strokeDasharray="5 7" />
          <line x1={-170} y1={-180} x2={-170} y2={180} stroke={colors.primary} strokeWidth={1.5} strokeDasharray="5 7" />
          <line x1={170} y1={-180} x2={170} y2={180} stroke={colors.primary} strokeWidth={1.5} strokeDasharray="5 7" />
        </g>
      </svg>

      {/* Background particles */}
      {[...Array(15)].map((_, i) => {
        const x = seededRandom(i + 700) * 1080;
        const speed = 0.3 + seededRandom(i + 710) * 0.3;
        const y = ((frame * speed + seededRandom(i + 720) * 1200) % 2100) - 100;
        return (
          <div key={i} style={{
            position: "absolute", left: x, top: y,
            width: 2.5, height: 2.5, borderRadius: "50%",
            backgroundColor: i % 4 === 0 ? colors.primary : i % 6 === 0 ? colors.accent : "rgba(255,255,255,0.2)",
            opacity: 0.25,
          }} />
        );
      })}

      {/* Title */}
      <div style={{
        position: "absolute", top: 150, textAlign: "center",
        opacity: titleSpring,
        transform: `translateY(${interpolate(titleSpring, [0, 1], [-25, 0])}px)`,
        fontFamily: fonts.title,
      }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 10,
          fontSize: 14, fontWeight: 700, color: colors.accent,
          letterSpacing: 5, textTransform: "uppercase", marginBottom: 12,
        }}>
          <div style={{ width: interpolate(titleSpring, [0, 1], [0, 30]), height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
          Verilerle
          <div style={{ width: interpolate(titleSpring, [0, 1], [0, 30]), height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
        </div>
        <h2 style={{
          fontSize: 48, fontWeight: 900, color: colors.textOnDark, margin: 0,
          textShadow: `0 0 30px ${colors.primary}35, 0 8px 30px rgba(0,0,0,0.5)`,
        }}>
          Proje Ölçeği
        </h2>
      </div>

      {/* Stats circles in 2x2 grid layout */}
      <div style={{
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: "60px 40px",
        justifyContent: "center",
        alignItems: "center",
        marginTop: 200,
        position: "relative",
      }}>
        {stats.map((stat, i) => (
          <CircularStat
            key={i}
            value={stat.value}
            suffix={stat.suffix}
            label={stat.label}
            delay={8 + i * 10}
            color={stat.color}
            size={240}
          />
        ))}
      </div>
    </AbsoluteFill>
  );
};
