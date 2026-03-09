import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, springPresets } from "../theme";

interface TechItemProps {
  name: string;
  icon: string;
  delay: number;
  angle: number;
  distance: number;
}

const TechOrbitItem: React.FC<TechItemProps> = ({
  name, icon, delay, angle, distance,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const adjustedFrame = Math.max(0, frame - delay);

  const appear = spring({
    frame: adjustedFrame,
    fps,
    config: springPresets.snappy,
  });

  // Orbit animation
  const orbitSpeed = 0.008;
  const currentAngle = angle + frame * orbitSpeed;
  const x = Math.cos(currentAngle) * distance;
  const y = Math.sin(currentAngle) * distance * 0.4; // Elliptical

  const floatY = Math.sin(frame * 0.05 + angle) * 3;

  return (
    <div
      style={{
        position: "absolute",
        transform: `translate(${x}px, ${y + floatY}px) scale(${appear})`,
        backgroundColor: colors.surface,
        borderRadius: 14,
        padding: "12px 20px",
        display: "flex",
        alignItems: "center",
        gap: 10,
        boxShadow: "0 4px 20px rgba(0,0,0,0.06), 0 1px 4px rgba(0,0,0,0.04)",
        border: `1px solid ${colors.primaryLight}`,
        whiteSpace: "nowrap",
      }}
    >
      <span style={{ fontSize: 22 }}>{icon}</span>
      <span style={{ fontSize: 14, fontWeight: 600, color: colors.textPrimary }}>
        {name}
      </span>
    </div>
  );
};

const techItems = [
  { name: "Flutter", icon: "💙", ring: 1 },
  { name: "Dart", icon: "🎯", ring: 1 },
  { name: "Riverpod", icon: "🔄", ring: 1 },
  { name: "GoRouter", icon: "🧭", ring: 1 },
  { name: "Supabase", icon: "⚡", ring: 1 },
  { name: "Drift", icon: "🗃️", ring: 2 },
  { name: "Freezed", icon: "❄️", ring: 2 },
  { name: "Sentry", icon: "🛡️", ring: 2 },
  { name: "AES-256", icon: "🔐", ring: 2 },
  { name: "Material 3", icon: "🎨", ring: 2 },
  { name: "fl_chart", icon: "📈", ring: 2 },
  { name: "3 Dil", icon: "🌍", ring: 2 },
];

export const TechStackScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleSpring = spring({ frame, fps, config: springPresets.smooth });

  // Center icon
  const centerScale = spring({
    frame: Math.max(0, frame - 5),
    fps,
    config: springPresets.bouncy,
  });

  const centerPulse = 1 + Math.sin(frame * 0.06) * 0.03;

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, #FAFFF8 0%, #F0F8F0 50%, #E8F5E9 100%)`,
        justifyContent: "center",
        alignItems: "center",
        overflow: "hidden",
      }}
    >
      {/* Background concentric circles */}
      {[250, 420].map((r, i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            width: r * 2,
            height: r * 2 * 0.4,
            border: `1px solid ${colors.primary}10`,
            borderRadius: "50%",
          }}
        />
      ))}

      {/* Title */}
      <div style={{
        position: "absolute", top: 60, textAlign: "center",
        opacity: titleSpring,
        transform: `translateY(${interpolate(titleSpring, [0, 1], [-20, 0])}px)`,
      }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: colors.accent, letterSpacing: 3, textTransform: "uppercase", marginBottom: 8 }}>
          Altyapi
        </div>
        <h2 style={{ fontSize: 44, fontWeight: 800, color: colors.primaryDark, margin: 0 }}>
          Teknoloji Yigini
        </h2>
      </div>

      {/* Center Flutter logo */}
      <div style={{
        transform: `scale(${centerScale * centerPulse})`,
        width: 100,
        height: 100,
        borderRadius: 28,
        background: `linear-gradient(135deg, ${colors.primary}, ${colors.primaryDark})`,
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        boxShadow: `0 8px 32px ${colors.primary}40`,
        zIndex: 10,
        marginTop: 30,
      }}>
        <span style={{ fontSize: 48 }}>💙</span>
      </div>

      {/* Orbiting tech items */}
      <div style={{ position: "absolute", top: "50%", left: "50%", marginTop: 15 }}>
        {techItems.map((tech, i) => {
          const ring1Count = techItems.filter(t => t.ring === 1).length;
          const isRing1 = tech.ring === 1;
          const ringIndex = isRing1
            ? techItems.filter((t, j) => t.ring === 1 && j <= i).length - 1
            : techItems.filter((t, j) => t.ring === 2 && j <= i).length - 1;
          const count = isRing1 ? ring1Count : techItems.length - ring1Count;
          const angle = (ringIndex / count) * Math.PI * 2;
          const distance = isRing1 ? 250 : 420;

          return (
            <TechOrbitItem
              key={i}
              name={tech.name}
              icon={tech.icon}
              delay={8 + i * 3}
              angle={angle}
              distance={distance}
            />
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
