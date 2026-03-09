import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, springPresets } from "../theme";

// Simulated app screens
const screens = [
  {
    title: "Kuslarim",
    color: colors.primary,
    items: [
      { name: "Mavi", gender: "Erkek", ring: "TR-2024-001", status: "Canli", color: "#42A5F5" },
      { name: "Sari", gender: "Disi", ring: "TR-2024-002", status: "Canli", color: "#FFD54F" },
      { name: "Yesil", gender: "Erkek", ring: "TR-2024-003", status: "Canli", color: "#66BB6A" },
      { name: "Mor", gender: "Disi", ring: "TR-2024-004", status: "Canli", color: "#AB47BC" },
    ],
  },
  {
    title: "Istatistikler",
    color: colors.budgieBlue,
    chart: true,
  },
  {
    title: "Genetik",
    color: colors.budgieTeal,
    punnett: true,
  },
];

const BirdListScreen: React.FC<{ frame: number }> = ({ frame }) => {
  const screen = screens[0];
  return (
    <div style={{ padding: 16, height: "100%" }}>
      {/* Status bar */}
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
        <span style={{ fontSize: 11, color: colors.textSecondary }}>9:41</span>
        <div style={{ display: "flex", gap: 4 }}>
          <div style={{ width: 14, height: 10, borderRadius: 2, backgroundColor: colors.textSecondary }} />
          <div style={{ width: 18, height: 10, borderRadius: 2, backgroundColor: colors.primary }} />
        </div>
      </div>

      {/* App bar */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: colors.textPrimary, margin: 0 }}>{screen.title}</h2>
        <div style={{ width: 36, height: 36, borderRadius: 18, backgroundColor: `${colors.primary}15`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16 }}>+</div>
      </div>

      {/* Search bar */}
      <div style={{ backgroundColor: "#F0F0F0", borderRadius: 12, padding: "10px 14px", marginBottom: 14, fontSize: 13, color: colors.textSecondary }}>
        Ara...
      </div>

      {/* Bird cards */}
      {screen.items.map((bird, i) => {
        const itemDelay = 10 + i * 6;
        const show = frame > itemDelay;
        const opacity = show ? Math.min(1, (frame - itemDelay) / 8) : 0;
        const translateY = show ? Math.max(0, 15 - (frame - itemDelay) * 2) : 15;

        return (
          <div
            key={i}
            style={{
              opacity,
              transform: `translateY(${translateY}px)`,
              display: "flex",
              alignItems: "center",
              gap: 12,
              padding: "12px 14px",
              backgroundColor: colors.surface,
              borderRadius: 14,
              marginBottom: 8,
              boxShadow: "0 1px 4px rgba(0,0,0,0.04)",
              border: "1px solid #F0F0F0",
            }}
          >
            <div style={{
              width: 40, height: 40, borderRadius: 20,
              background: `linear-gradient(135deg, ${bird.color}40, ${bird.color}20)`,
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 18,
            }}>
              🐦
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 600, color: colors.textPrimary }}>{bird.name}</div>
              <div style={{ fontSize: 11, color: colors.textSecondary }}>{bird.ring} · {bird.gender}</div>
            </div>
            <div style={{
              fontSize: 10, fontWeight: 600, color: colors.primary,
              backgroundColor: `${colors.primary}12`, borderRadius: 6, padding: "3px 8px",
            }}>
              {bird.status}
            </div>
          </div>
        );
      })}
    </div>
  );
};

const StatsScreen: React.FC<{ frame: number }> = ({ frame }) => {
  const barData = [65, 82, 45, 90, 73, 88, 55];
  const months = ["Oca", "Sub", "Mar", "Nis", "May", "Haz", "Tem"];

  return (
    <div style={{ padding: 16, height: "100%" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
        <span style={{ fontSize: 11, color: colors.textSecondary }}>9:41</span>
      </div>
      <h2 style={{ fontSize: 22, fontWeight: 700, color: colors.textPrimary, margin: "0 0 20px" }}>Istatistikler</h2>

      {/* Mini stat cards */}
      <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
        {[
          { label: "Toplam Kus", value: "24", color: colors.primary },
          { label: "Basari %", value: "78", color: colors.accent },
          { label: "Yavru", value: "12", color: colors.budgieBlue },
        ].map((stat, i) => {
          const progress = Math.min(1, Math.max(0, (frame - 10 - i * 5) / 15));
          const displayVal = Math.round(parseInt(stat.value) * progress);
          return (
            <div key={i} style={{
              flex: 1, backgroundColor: `${stat.color}10`, borderRadius: 12, padding: "12px 10px",
              textAlign: "center", border: `1px solid ${stat.color}20`,
            }}>
              <div style={{ fontSize: 22, fontWeight: 800, color: stat.color }}>{displayVal}</div>
              <div style={{ fontSize: 9, color: colors.textSecondary, marginTop: 2 }}>{stat.label}</div>
            </div>
          );
        })}
      </div>

      {/* Bar chart */}
      <div style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 16, border: "1px solid #F0F0F0" }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: colors.textPrimary, marginBottom: 12 }}>Aylik Ureme</div>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height: 120 }}>
          {barData.map((val, i) => {
            const barProgress = Math.min(1, Math.max(0, (frame - 20 - i * 3) / 15));
            return (
              <div key={i} style={{ flex: 1, textAlign: "center" }}>
                <div style={{
                  height: val * barProgress * 1.1,
                  backgroundColor: i === 3 ? colors.accent : colors.primary,
                  borderRadius: "4px 4px 0 0",
                  opacity: 0.8 + (i === 3 ? 0.2 : 0),
                  transition: "height 0.3s",
                }} />
                <div style={{ fontSize: 8, color: colors.textSecondary, marginTop: 4 }}>{months[i]}</div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

const GeneticsScreen: React.FC<{ frame: number }> = ({ frame }) => {
  const punnettData = [
    ["", "G", "g"],
    ["G", "GG", "Gg"],
    ["g", "Gg", "gg"],
  ];

  return (
    <div style={{ padding: 16, height: "100%" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
        <span style={{ fontSize: 11, color: colors.textSecondary }}>9:41</span>
      </div>
      <h2 style={{ fontSize: 22, fontWeight: 700, color: colors.textPrimary, margin: "0 0 16px" }}>Genetik</h2>

      {/* Parents */}
      <div style={{ display: "flex", gap: 10, marginBottom: 16 }}>
        {[
          { label: "Baba", emoji: "🐦", color: colors.budgieBlue },
          { label: "Anne", emoji: "🐦", color: "#E91E63" },
        ].map((parent, i) => (
          <div key={i} style={{
            flex: 1, display: "flex", alignItems: "center", gap: 8,
            backgroundColor: `${parent.color}10`, borderRadius: 12, padding: "10px 12px",
            border: `1px solid ${parent.color}25`,
          }}>
            <span style={{ fontSize: 20 }}>{parent.emoji}</span>
            <div>
              <div style={{ fontSize: 12, fontWeight: 600, color: colors.textPrimary }}>{parent.label}</div>
              <div style={{ fontSize: 9, color: colors.textSecondary }}>Gg (Tasiyici)</div>
            </div>
          </div>
        ))}
      </div>

      {/* Punnett square */}
      <div style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 14, border: "1px solid #F0F0F0" }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: colors.textPrimary, marginBottom: 10 }}>Punnett Karesi</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 4 }}>
          {punnettData.flat().map((cell, i) => {
            const row = Math.floor(i / 3);
            const col = i % 3;
            const isHeader = row === 0 || col === 0;
            const cellDelay = 15 + (row * 3 + col) * 4;
            const show = frame > cellDelay;
            const opacity = show ? Math.min(1, (frame - cellDelay) / 8) : 0;

            return (
              <div key={i} style={{
                opacity: isHeader ? 1 : opacity,
                padding: "10px 0",
                textAlign: "center",
                fontSize: isHeader ? 13 : 14,
                fontWeight: isHeader ? 700 : 600,
                color: isHeader ? colors.budgieTeal : colors.textPrimary,
                backgroundColor: isHeader ? `${colors.budgieTeal}08` : cell === "gg" ? `${colors.accent}15` : `${colors.primary}08`,
                borderRadius: 8,
              }}>
                {cell}
              </div>
            );
          })}
        </div>

        {/* Result */}
        <div style={{
          marginTop: 10, padding: "8px 12px", backgroundColor: `${colors.accent}10`,
          borderRadius: 8, fontSize: 11, color: colors.textSecondary, textAlign: "center",
        }}>
          %25 GG · %50 Gg · %25 gg
        </div>
      </div>
    </div>
  );
};

export const PhoneDemoScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Phone entrance
  const phoneScale = spring({ frame, fps, config: springPresets.smooth });
  const phoneY = interpolate(phoneScale, [0, 1], [60, 0]);

  // Screen switching
  const screenIndex = frame < 40 ? 0 : frame < 75 ? 1 : 2;
  const screenFrame = frame < 40 ? frame : frame < 75 ? frame - 40 : frame - 75;

  // Screen transition
  const transition = frame === 40 || frame === 75
    ? interpolate(frame % 40, [0, 5], [0, 1], { extrapolateRight: "clamp" })
    : 1;

  // Title
  const titleOpacity = interpolate(frame, [0, 15], [0, 1], { extrapolateRight: "clamp" });

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg, #F8FFF8 0%, #E8F5E9 50%, #C8E6C9 100%)`,
        justifyContent: "center",
        alignItems: "center",
        overflow: "hidden",
      }}
    >
      {/* Background decoration */}
      <div style={{
        position: "absolute", width: 800, height: 800, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.primary}08 0%, transparent 70%)`,
        filter: "blur(40px)",
      }} />

      {/* Title */}
      <div style={{
        position: "absolute", top: 80, opacity: titleOpacity, textAlign: "center",
      }}>
        <h2 style={{ fontSize: 44, fontWeight: 800, color: colors.primaryDark, margin: 0 }}>
          Uygulama Onizleme
        </h2>
        <p style={{ fontSize: 18, color: colors.textSecondary, margin: "8px 0 0" }}>
          Guclu ozellikler, sade arayuz
        </p>
      </div>

      {/* Phone frame */}
      <div
        style={{
          transform: `scale(${phoneScale}) translateY(${phoneY}px)`,
          marginTop: 80,
        }}
      >
        <div
          style={{
            width: 320,
            height: 640,
            backgroundColor: "#1A1A1A",
            borderRadius: 40,
            padding: 8,
            boxShadow: "0 20px 80px rgba(0,0,0,0.25), 0 4px 20px rgba(0,0,0,0.15)",
            position: "relative",
          }}
        >
          {/* Notch */}
          <div style={{
            position: "absolute", top: 8, left: "50%", transform: "translateX(-50%)",
            width: 120, height: 28, backgroundColor: "#1A1A1A", borderRadius: "0 0 16px 16px",
            zIndex: 10,
          }} />

          {/* Screen */}
          <div
            style={{
              width: "100%",
              height: "100%",
              backgroundColor: colors.background,
              borderRadius: 32,
              overflow: "hidden",
              opacity: transition,
            }}
          >
            {screenIndex === 0 && <BirdListScreen frame={screenFrame} />}
            {screenIndex === 1 && <StatsScreen frame={screenFrame} />}
            {screenIndex === 2 && <GeneticsScreen frame={screenFrame} />}
          </div>

          {/* Home indicator */}
          <div style={{
            position: "absolute", bottom: 12, left: "50%", transform: "translateX(-50%)",
            width: 100, height: 4, backgroundColor: "rgba(255,255,255,0.3)", borderRadius: 2,
          }} />
        </div>
      </div>

      {/* Screen indicator dots */}
      <div style={{
        position: "absolute", bottom: 60, display: "flex", gap: 10,
      }}>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{
            width: screenIndex === i ? 24 : 8, height: 8,
            borderRadius: 4,
            backgroundColor: screenIndex === i ? colors.primary : `${colors.primary}30`,
            transition: "width 0.3s",
          }} />
        ))}
      </div>
    </AbsoluteFill>
  );
};
