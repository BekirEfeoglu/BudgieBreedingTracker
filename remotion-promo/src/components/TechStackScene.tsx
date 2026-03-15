import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets } from "../theme";

// ─── Connection beam between center and orbit item ──────────
const ConnectionBeam: React.FC<{
  x: number; y: number; delay: number; color: string;
}> = ({ x, y, delay, color }) => {
  const frame = useCurrentFrame();
  const elapsed = Math.max(0, frame - delay);
  const progress = interpolate(elapsed, [0, 15], [0, 1], { extrapolateRight: "clamp" });
  if (progress <= 0) return null;
  const opacity = 0.08 + Math.sin(frame * 0.06) * 0.04;
  return (
    <line x1={0} y1={0} x2={x * progress} y2={y * progress}
      stroke={color} strokeWidth={1} opacity={opacity}
      strokeDasharray="3 5"
    />
  );
};

interface TechItemProps {
  name: string;
  icon: string;
  delay: number;
  angle: number;
  distance: number;
  color?: string;
}

const TechOrbitItem: React.FC<TechItemProps> = ({ name, icon, delay, angle, distance, color }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const adjustedFrame = Math.max(0, frame - delay);

  const appear = spring({ frame: adjustedFrame, fps, config: springPresets.pop });

  const orbitSpeed = 0.008;
  const currentAngle = angle + frame * orbitSpeed;
  const x = Math.cos(currentAngle) * distance;
  const y = Math.sin(currentAngle) * distance * 0.4;

  const floatY = Math.sin(frame * 0.05 + angle) * 5;

  // Glow intensity
  const glowAlpha = 0.15 + Math.sin(frame * 0.07 + angle * 3) * 0.1;

  return (
    <div style={{
      position: "absolute",
      transform: `translate(${x}px, ${y + floatY}px) scale(${appear})`,
      backgroundColor: "rgba(255,255,255,0.04)",
      borderRadius: 16, padding: "12px 22px",
      display: "flex", alignItems: "center", gap: 10,
      boxShadow: `0 8px 25px rgba(0,0,0,0.3), 0 0 20px ${color || colors.primary}${Math.round(glowAlpha * 255).toString(16).padStart(2, "0")}`,
      border: `1px solid rgba(255,255,255,0.08)`,
      backdropFilter: "blur(12px)", whiteSpace: "nowrap",
      fontFamily: fonts.body,
    }}>
      <span style={{ fontSize: 22 }}>{icon}</span>
      <span style={{ fontSize: 15, fontWeight: 700, color: colors.textOnDark }}>{name}</span>
    </div>
  );
};

const techItems = [
  { name: "Flutter 3",       icon: "🐦", ring: 1, color: colors.budgieBlue },
  { name: "Dart 3.8",        icon: "🎯", ring: 1, color: colors.primary },
  { name: "Riverpod 3",      icon: "🔄", ring: 1, color: colors.accent },
  { name: "Supabase",        icon: "⚡", ring: 1, color: colors.budgieGreen },
  { name: "GoRouter",        icon: "🧭", ring: 2, color: colors.budgieTeal },
  { name: "Drift (SQLite)",  icon: "🗃️", ring: 2, color: colors.budgieBlue },
  { name: "Freezed 3",       icon: "❄️", ring: 2, color: colors.budgieBlue },
  { name: "AES-256",         icon: "🔐", ring: 2, color: colors.heartRed },
  { name: "Sentry",          icon: "🛡️", ring: 2, color: colors.budgieYellow },
  { name: "3 Dil (TR/EN/DE)",icon: "🌍", ring: 2, color: colors.budgieTeal },
];

export const TechStackScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleSpring = spring({ frame, fps, config: springPresets.smooth });

  const centerScale = spring({ frame: Math.max(0, frame - 5), fps, config: springPresets.bouncy });
  const centerPulse = 1 + Math.sin(frame * 0.07) * 0.04;
  const centerRotate = frame * 0.15;

  // Calculate positions for connection beams
  const getItemPos = (i: number) => {
    const ring1Count = techItems.filter(t => t.ring === 1).length;
    const isRing1 = techItems[i].ring === 1;
    const ringIndex = isRing1
      ? techItems.filter((t, j) => t.ring === 1 && j <= i).length - 1
      : techItems.filter((t, j) => t.ring === 2 && j <= i).length - 1;
    const count = isRing1 ? ring1Count : techItems.length - ring1Count;
    const angle = (ringIndex / count) * Math.PI * 2 + frame * 0.008;
    const distance = isRing1 ? 270 : 440;
    return {
      x: Math.cos(angle) * distance,
      y: Math.sin(angle) * distance * 0.4,
    };
  };

  return (
    <AbsoluteFill style={{
      backgroundColor: colors.background,
      justifyContent: "center", alignItems: "center", overflow: "hidden",
    }}>
      {/* Radial glow */}
      <div style={{
        position: "absolute", width: 900, height: 900, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.primary}06 0%, transparent 65%)`,
        filter: "blur(60px)",
        transform: `scale(${1 + Math.sin(frame * 0.03) * 0.05})`,
      }} />

      {/* Orbit rings */}
      {[270, 440].map((r, i) => (
        <div key={i} style={{
          position: "absolute",
          width: r * 2, height: r * 2 * 0.4,
          border: `1px solid rgba(255,255,255,${0.04 + Math.sin(frame * 0.04 + i) * 0.02})`,
          borderRadius: "50%",
          transform: `perspective(1000px) rotateX(8deg) rotate(${frame * 0.1 * (i === 0 ? 1 : -1)}deg)`,
        }} />
      ))}

      {/* Connection beams (SVG) */}
      <svg style={{ position: "absolute", width: "100%", height: "100%", overflow: "visible" }}
        viewBox="-960 -540 1920 1080"
      >
        <g transform="translate(0, 20)">
          {techItems.map((tech, i) => {
            const pos = getItemPos(i);
            return (
              <ConnectionBeam key={i} x={pos.x} y={pos.y} delay={10 + i * 4} color={tech.color} />
            );
          })}
        </g>
      </svg>

      {/* Title */}
      <div style={{
        position: "absolute", top: 70, textAlign: "center",
        opacity: titleSpring,
        transform: `translateY(${interpolate(titleSpring, [0, 1], [-20, 0])}px)`,
        fontFamily: fonts.title,
      }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 10,
          fontSize: 14, fontWeight: 700, color: colors.accent,
          letterSpacing: 5, textTransform: "uppercase", marginBottom: 12,
        }}>
          <div style={{ width: interpolate(titleSpring, [0, 1], [0, 30]), height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
          Altyapı
          <div style={{ width: interpolate(titleSpring, [0, 1], [0, 30]), height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
        </div>
        <h2 style={{ fontSize: 48, fontWeight: 900, color: colors.textOnDark, margin: 0, textShadow: `0 0 25px ${colors.primary}30` }}>
          Teknoloji Stack
        </h2>
      </div>

      {/* Center icon */}
      <div style={{
        transform: `scale(${centerScale * centerPulse}) rotate(${centerRotate}deg)`,
        width: 110, height: 110, borderRadius: 30,
        background: `linear-gradient(135deg, ${colors.primary}, ${colors.primaryDark})`,
        display: "flex", justifyContent: "center", alignItems: "center",
        boxShadow: `0 0 50px ${colors.primary}50, inset 0 1px 1px rgba(255,255,255,0.2)`,
        zIndex: 10, marginTop: 35,
        border: "1px solid rgba(255,255,255,0.15)",
      }}>
        <span style={{ fontSize: 55, transform: `rotate(${-centerRotate}deg)` }}>🚀</span>
      </div>

      {/* Orbiting tech items */}
      <div style={{ position: "absolute", top: "50%", left: "50%", marginTop: 17 }}>
        {techItems.map((tech, i) => {
          const ring1Count = techItems.filter(t => t.ring === 1).length;
          const isRing1 = tech.ring === 1;
          const ringIndex = isRing1
            ? techItems.filter((t, j) => t.ring === 1 && j <= i).length - 1
            : techItems.filter((t, j) => t.ring === 2 && j <= i).length - 1;
          const count = isRing1 ? ring1Count : techItems.length - ring1Count;
          const angle = (ringIndex / count) * Math.PI * 2;
          const distance = isRing1 ? 270 : 440;

          return (
            <TechOrbitItem
              key={i} name={tech.name} icon={tech.icon}
              delay={8 + i * 3} angle={angle} distance={distance} color={tech.color}
            />
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
