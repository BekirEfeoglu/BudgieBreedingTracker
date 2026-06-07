import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets } from "../theme";

const techItems = [
  { name: "Flutter 3",       icon: "🐦", color: colors.budgieBlue, strand: 0, index: 0 },
  { name: "Dart 3.8",        icon: "🎯", color: colors.primary,    strand: 1, index: 0 },
  { name: "Riverpod 3",      icon: "🔄", color: colors.accent,     strand: 0, index: 1 },
  { name: "Supabase",        icon: "⚡", color: colors.budgieGreen,  strand: 1, index: 1 },
  { name: "GoRouter",        icon: "🧭", color: colors.budgieTeal,   strand: 0, index: 2 },
  { name: "Drift (SQLite)",  icon: "🗃️", color: colors.budgieBlue,   strand: 1, index: 2 },
  { name: "Freezed 3",       icon: "❄️", color: colors.budgieBlue,   strand: 0, index: 3 },
  { name: "AES-256 Kripto",  icon: "🔐", color: colors.heartRed,     strand: 1, index: 3 },
  { name: "Sentry",          icon: "🛡️", color: colors.budgieYellow,  strand: 0, index: 4 },
  { name: "3 Dil Desteği",   icon: "🌍", color: colors.budgieTeal,   strand: 1, index: 4 },
];

export const TechStackSceneReels: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleSpring = spring({ frame, fps, config: springPresets.smooth });
  const centerScale = spring({ frame: Math.max(0, frame - 5), fps, config: springPresets.bouncy });
  const centerPulse = 1 + Math.sin(frame * 0.08) * 0.04;

  const helixSpeed = 0.035;
  const helixRadius = 260;
  const helixHeight = 650;
  const verticalOffset = 80; // Offset downward to balance screen

  // Helper to compute 3D coordinate and layout properties for any item
  const getHelixItemProps = (item: typeof techItems[number], i: number) => {
    // Height is distributed from top to bottom
    const progress = i / (techItems.length - 1);
    const baseY = -helixHeight / 2 + progress * helixHeight + verticalOffset;
    
    // Twist angle (creates the helical twist)
    const twistAngle = progress * Math.PI * 2.2;
    // Strand offset (Strand A is 0, Strand B is 180 degrees opposite)
    const strandAngle = item.strand === 0 ? 0 : Math.PI;
    
    const currentAngle = twistAngle + strandAngle + frame * helixSpeed;
    const x = Math.cos(currentAngle) * helixRadius;
    const z = Math.sin(currentAngle); // Depth representation (-1 is back, 1 is front)

    // Dynamic sizing and opacity based on depth
    const scale = interpolate(z, [-1, 1], [0.75, 1.15]);
    const opacity = interpolate(z, [-1, 1], [0.45, 1]);
    const zIndex = Math.round(interpolate(z, [-1, 1], [5, 25]));

    return {
      x,
      y: baseY + Math.sin(frame * 0.06 + i) * 6, // dynamic float
      scale,
      opacity,
      zIndex,
      color: item.color,
    };
  };

  return (
    <AbsoluteFill style={{
      backgroundColor: colors.background,
      justifyContent: "center", alignItems: "center", overflow: "hidden",
    }}>
      {/* Intense radial neon glow behind rocket */}
      <div style={{
        position: "absolute", width: 750, height: 750, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.primary}08 0%, ${colors.accent}04 45%, transparent 70%)`,
        filter: "blur(50px)",
        transform: `scale(${1 + Math.sin(frame * 0.035) * 0.06})`,
      }} />

      {/* Cyber grid lines */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `linear-gradient(rgba(255,255,255,0.012) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.012) 1px, transparent 1px)`,
        backgroundSize: "85px 85px",
        transform: `translateY(${frame * 0.25}px)`,
        opacity: 0.35,
      }} />

      {/* Helix connecting beams (Hydrogen bonds) - SVG */}
      <svg style={{ position: "absolute", width: "100%", height: "100%", overflow: "visible" }}
        viewBox="-540 -960 1080 1920"
      >
        {/* We draw lines connecting matching index pairs from Strand A and B */}
        {[0, 1, 2, 3, 4].map((idx) => {
          const itemA = techItems.find(t => t.strand === 0 && t.index === idx)!;
          const itemB = techItems.find(t => t.strand === 1 && t.index === idx)!;
          
          const iA = techItems.indexOf(itemA);
          const iB = techItems.indexOf(itemB);

          const propsA = getHelixItemProps(itemA, iA);
          const propsB = getHelixItemProps(itemB, iB);

          // Connection beam properties based on average depth
          const avgZ = (propsA.zIndex + propsB.zIndex) / 2;
          const beamOpacity = interpolate(avgZ, [5, 25], [0.03, 0.18]);
          const beamSpring = spring({
            frame: Math.max(0, frame - (10 + idx * 5)),
            fps,
            config: springPresets.smooth,
          });

          return (
            <line
              key={idx}
              x1={propsA.x * beamSpring}
              y1={propsA.y}
              x2={propsB.x * beamSpring}
              y2={propsB.y}
              stroke={`url(#gradient-${idx})`}
              strokeWidth={2.5}
              opacity={beamOpacity}
              strokeDasharray="4 6"
            />
          );
        })}
        
        {/* Gradients definition for connection beams */}
        <defs>
          {[0, 1, 2, 3, 4].map((idx) => {
            const itemA = techItems.find(t => t.strand === 0 && t.index === idx)!;
            const itemB = techItems.find(t => t.strand === 1 && t.index === idx)!;
            return (
              <linearGradient key={idx} id={`gradient-${idx}`} x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor={itemA.color} />
                <stop offset="100%" stopColor={itemB.color} />
              </linearGradient>
            );
          })}
        </defs>
      </svg>

      {/* Title */}
      <div style={{
        position: "absolute", top: 160, textAlign: "center",
        opacity: titleSpring,
        transform: `translateY(${interpolate(titleSpring, [0, 1], [-20, 0])}px)`,
        fontFamily: fonts.title,
        zIndex: 30,
      }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 10,
          fontSize: 14, fontWeight: 700, color: colors.accent,
          letterSpacing: 5, textTransform: "uppercase", marginBottom: 12,
        }}>
          <div style={{ width: interpolate(titleSpring, [0, 1], [0, 30]), height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
          Güçlü Altyapı
          <div style={{ width: interpolate(titleSpring, [0, 1], [0, 30]), height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
        </div>
        <h2 style={{
          fontSize: 44, fontWeight: 900, color: colors.textOnDark, margin: 0,
          textShadow: `0 0 25px ${colors.primary}30, 0 4px 10px rgba(0,0,0,0.5)`,
        }}>
          Teknoloji Stack
        </h2>
      </div>

      {/* Center icon (Rocket 🚀 with neon engine fire glow) */}
      <div style={{
        transform: `scale(${centerScale * centerPulse})`,
        width: 105, height: 105, borderRadius: 28,
        background: `linear-gradient(135deg, ${colors.primary}, ${colors.primaryDark})`,
        display: "flex", justifyContent: "center", alignItems: "center",
        boxShadow: `0 0 50px ${colors.primary}45, 0 15px 35px rgba(0,0,0,0.4), inset 0 1px 1px rgba(255,255,255,0.25)`,
        zIndex: 15,
        border: "1px solid rgba(255,255,255,0.15)",
        marginTop: verticalOffset, // Align with vertical offset
        position: "relative",
      }}>
        {/* Pulsing engine fire aura */}
        <div style={{
          position: "absolute", bottom: -20, width: 40, height: 40, borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.budgieYellow}90 0%, transparent 70%)`,
          filter: "blur(8px)",
          transform: `scale(${1.2 + Math.sin(frame * 0.2) * 0.2})`,
        }} />
        <span style={{ fontSize: 50 }}>🚀</span>
      </div>

      {/* Orbiting Helix tech items */}
      <div style={{ position: "absolute", top: "50%", left: "50%", width: 0, height: 0 }}>
        {techItems.map((tech, i) => {
          const props = getHelixItemProps(tech, i);
          const appear = spring({
            frame: Math.max(0, frame - (8 + i * 3.5)),
            fps,
            config: springPresets.pop,
          });

          return (
            <div
              key={i}
              style={{
                position: "absolute",
                left: props.x,
                top: props.y,
                transform: `translate(-50%, -50%) scale(${appear * props.scale})`,
                opacity: appear * props.opacity,
                zIndex: props.zIndex,
                backgroundColor: "rgba(26,26,30,0.85)",
                borderRadius: 16, padding: "10px 18px",
                display: "flex", alignItems: "center", gap: 8,
                boxShadow: `0 8px 25px rgba(0,0,0,0.4), 0 0 20px ${props.color}${Math.round(0.12 * 255).toString(16).padStart(2, "0")}, inset 0 1px 0 rgba(255,255,255,0.05)`,
                border: `1px solid rgba(255,255,255,0.08)`,
                backdropFilter: "blur(15px)", whiteSpace: "nowrap",
                fontFamily: fonts.body,
              }}
            >
              <span style={{ fontSize: 18 }}>{tech.icon}</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: colors.textOnDark }}>{tech.name}</span>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
