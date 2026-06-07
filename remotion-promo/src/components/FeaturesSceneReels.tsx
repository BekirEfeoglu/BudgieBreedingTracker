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

export const FeaturesSceneReels: React.FC = () => {
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
        padding: "160px 40px 60px",
        overflow: "hidden",
      }}
    >
      {/* Intense dual-color animated neon background */}
      <div style={{
        position: "absolute", inset: 0,
        background: `
          radial-gradient(circle at ${50 + Math.sin(frame * 0.025) * 15}% ${40 + Math.cos(frame * 0.02) * 15}%, ${colors.primary}0f 0%, transparent 60%),
          radial-gradient(circle at ${45 + Math.cos(frame * 0.02) * 15}% ${60 + Math.sin(frame * 0.025) * 15}%, ${colors.accent}0f 0%, transparent 60%)
        `,
        filter: "blur(20px)",
      }} />

      {/* Floating background particles */}
      {[...Array(15)].map((_, i) => {
        const x = seededRandom(i + 300) * 1080;
        const speed = 0.5 + seededRandom(i + 310) * 0.4;
        const y = ((frame * speed + seededRandom(i + 320) * 1200) % 2100) - 100;
        const size = 2 + seededRandom(i + 330) * 3;
        const opacity = 0.15 + seededRandom(i + 340) * 0.18;
        return (
          <div key={i} style={{
            position: "absolute", left: x, top: y,
            width: size, height: size, borderRadius: "50%",
            backgroundColor: i % 3 === 0 ? colors.primary : i % 5 === 0 ? colors.accent : "rgba(255,255,255,0.25)",
            opacity, filter: "blur(0.5px)",
          }} />
        );
      })}

      {/* Cyber mesh grid lines in background */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `linear-gradient(rgba(255,255,255,0.012) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.012) 1px, transparent 1px)`,
        backgroundSize: "60px 60px",
        transform: `perspective(600px) rotateX(60deg) translateY(${frame * 0.6}px)`,
        opacity: 0.3,
        pointerEvents: "none",
      }} />

      {/* Section title */}
      <div style={{
        position: "absolute", top: 120, opacity: titleSpring,
        transform: `translateY(${titleY}px)`, textAlign: "center", fontFamily: fonts.title,
        zIndex: 20,
      }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 10,
          fontSize: 14, fontWeight: 700, color: colors.accent,
          letterSpacing: 5, textTransform: "uppercase", marginBottom: 12,
        }}>
          <div style={{
            width: interpolate(titleSpring, [0, 1], [0, 35]), height: 1,
            backgroundColor: colors.accent, opacity: 0.5,
          }} />
          Neler Yapabilirsiniz?
          <div style={{
            width: interpolate(titleSpring, [0, 1], [0, 35]), height: 1,
            backgroundColor: colors.accent, opacity: 0.5,
          }} />
        </div>
        <h2 style={{
          fontSize: 52, fontWeight: 900, color: colors.textOnDark, margin: 0,
          textShadow: `0 0 35px ${colors.primary}35, 0 4px 15px rgba(0,0,0,0.6)`,
        }}>
          <span style={{
            background: `linear-gradient(135deg, ${colors.primary}, ${colors.budgieYellow})`,
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            fontWeight: 950,
          }}>{featureCount}</span> Güçlü Özellik
        </h2>
      </div>

      {/* Feature cards — 2x3 grid optimized for vertical layout */}
      <div style={{
        display: "flex",
        flexWrap: "wrap",
        gap: 20,
        justifyContent: "center",
        alignItems: "center",
        maxWidth: 960,
        marginTop: 180,
        zIndex: 10,
      }}>
        {features.map((feature, i) => {
          const delay = 8 + i * 5;
          const cardSpring = spring({
            frame: Math.max(0, frame - delay),
            fps,
            config: springPresets.pop,
          });
          const scale = interpolate(cardSpring, [0, 1], [0.88, 1]);
          const rotate = interpolate(cardSpring, [0, 1], [i % 2 === 0 ? -3 : 3, 0]);

          return (
            <div key={i} style={{
              transform: `scale(${scale}) rotate(${rotate}deg)`,
              transition: "transform 0.08s",
            }}>
              <FeatureCard
                emoji={feature.emoji}
                title={feature.title}
                description={feature.description}
                delay={delay}
                index={i}
                accentColor={feature.accentColor}
              />
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
