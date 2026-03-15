import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets, seededRandom } from "../theme";
import { FeatureCard } from "./FeatureCard";

const features = [
  { emoji: "🐦", title: "Kuş Yönetimi",       description: "Detaylı profiller, halka takibi ve fotoğraf galerisi",      accentColor: colors.primary },
  { emoji: "🧬", title: "Genetik Hesaplama",   description: "27 mutasyon, Punnett karesi ve akrabalık uyarısı",          accentColor: colors.accent },
  { emoji: "🐣", title: "Yavru Takibi",        description: "Büyüme ölçümleri, gelişim aşamaları ve sütten kesme",       accentColor: colors.budgieYellow },
  { emoji: "🥚", title: "Yumurta & Kuluçka",   description: "18 günlük kuluçka sürecini gün gün izleyin",                accentColor: colors.budgieBlue },
  { emoji: "🌳", title: "Soy Ağacı",           description: "Çok nesilli pedigree ve akrabalık görüntüleme",             accentColor: colors.budgieTeal },
  { emoji: "📊", title: "İstatistikler",       description: "Grafikler, PDF/Excel export ve başarı analizleri",          accentColor: colors.budgieGreen },
];

export const FeaturesScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleSpring = spring({ frame, fps, config: springPresets.smooth });
  const titleY = interpolate(titleSpring, [0, 1], [-40, 0]);

  // Animated counter for feature count
  const countProgress = interpolate(frame, [5, 30], [0, 1], { extrapolateRight: "clamp" });
  const featureCount = Math.round(6 * countProgress);

  return (
    <AbsoluteFill
      style={{
        backgroundColor: colors.background,
        justifyContent: "center",
        alignItems: "center",
        padding: 60,
        overflow: "hidden",
      }}
    >
      {/* Animated radial gradient background */}
      <div style={{
        position: "absolute", inset: 0,
        background: `radial-gradient(ellipse at ${50 + Math.sin(frame * 0.02) * 10}% ${50 + Math.cos(frame * 0.015) * 10}%, rgba(20, 241, 149, 0.06) 0%, transparent 60%)`,
      }} />

      {/* Floating background particles */}
      {[...Array(12)].map((_, i) => {
        const x = seededRandom(i + 300) * 1920;
        const speed = 0.3 + seededRandom(i + 310) * 0.4;
        const y = ((frame * speed + seededRandom(i + 320) * 800) % 1200) - 100;
        const size = 2 + seededRandom(i + 330) * 3;
        const opacity = 0.15 + seededRandom(i + 340) * 0.15;
        return (
          <div key={i} style={{
            position: "absolute", left: x, top: y,
            width: size, height: size, borderRadius: "50%",
            backgroundColor: i % 3 === 0 ? colors.primary : "rgba(255,255,255,0.3)",
            opacity, filter: "blur(0.5px)",
          }} />
        );
      })}

      {/* Connecting lines between card positions */}
      <svg style={{ position: "absolute", inset: 0, opacity: 0.04 }} viewBox="0 0 1920 1080">
        {[0, 1, 2, 3, 4].map((i) => {
          const lineProgress = interpolate(frame, [20 + i * 8, 40 + i * 8], [0, 1], { extrapolateRight: "clamp" });
          const y1 = 300 + Math.floor(i / 2) * 120;
          const y2 = 300 + Math.floor((i + 1) / 2) * 120;
          return (
            <line key={i} x1={700} y1={y1} x2={1200} y2={y2}
              stroke={colors.primary} strokeWidth={1}
              strokeDasharray={`${lineProgress * 600} 600`}
            />
          );
        })}
      </svg>

      {/* Section title */}
      <div style={{
        position: "absolute", top: 55, opacity: titleSpring,
        transform: `translateY(${titleY}px)`, textAlign: "center", fontFamily: fonts.title,
      }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 10,
          fontSize: 14, fontWeight: 700, color: colors.accent,
          letterSpacing: 5, textTransform: "uppercase", marginBottom: 12,
        }}>
          <div style={{
            width: interpolate(titleSpring, [0, 1], [0, 40]), height: 1,
            backgroundColor: colors.accent, opacity: 0.5,
          }} />
          Neler Yapabilirsiniz?
          <div style={{
            width: interpolate(titleSpring, [0, 1], [0, 40]), height: 1,
            backgroundColor: colors.accent, opacity: 0.5,
          }} />
        </div>
        <h2 style={{
          fontSize: 58, fontWeight: 900, color: colors.textOnDark, margin: 0,
          textShadow: `0 0 30px ${colors.primary}25`,
        }}>
          <span style={{ color: colors.primary }}>{featureCount}</span> Özellik
        </h2>
      </div>

      {/* Feature cards — 3x2 grid */}
      <div style={{
        display: "flex", flexWrap: "wrap", gap: 18,
        justifyContent: "center", marginTop: 100, maxWidth: 1000,
      }}>
        {features.map((feature, i) => (
          <FeatureCard
            key={i}
            emoji={feature.emoji}
            title={feature.title}
            description={feature.description}
            delay={12 + i * 7}
            index={i}
            accentColor={feature.accentColor}
          />
        ))}
      </div>
    </AbsoluteFill>
  );
};
