import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, springPresets } from "../theme";
import { FeatureCard } from "./FeatureCard";

const features = [
  {
    emoji: "🐦",
    title: "Kus Yonetimi",
    description: "Tum kuslarinizi detayli profilleriyle takip edin",
    accentColor: colors.primary,
  },
  {
    emoji: "🥚",
    title: "Yumurta & Kulucka",
    description: "18 gunluk kulucka surecini gun gun izleyin",
    accentColor: colors.accent,
  },
  {
    emoji: "🐣",
    title: "Yavru Takibi",
    description: "Buyume olcumleri ve gelisim asamalari",
    accentColor: colors.budgieYellow,
  },
  {
    emoji: "🧬",
    title: "Genetik Hesaplama",
    description: "27 mutasyon, Punnett karesi ve akrabalik uyarisi",
    accentColor: colors.budgieTeal,
  },
  {
    emoji: "🌳",
    title: "Soy Agaci",
    description: "Cok nesilli akrabalik goruntulemesi",
    accentColor: colors.budgieGreen,
  },
  {
    emoji: "📊",
    title: "Istatistikler & Raporlar",
    description: "Grafikler, PDF/Excel export, detayli analizler",
    accentColor: colors.budgieBlue,
  },
];

export const FeaturesScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Title entrance
  const titleSpring = spring({ frame, fps, config: springPresets.smooth });
  const titleY = interpolate(titleSpring, [0, 1], [-30, 0]);

  // Decorative line
  const lineWidth = interpolate(frame, [10, 30], [0, 80], {
    extrapolateRight: "clamp",
  });

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
      {/* Subtle background pattern */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `radial-gradient(${colors.primary}06 1px, transparent 1px)`,
        backgroundSize: "24px 24px",
      }} />

      {/* Background decoration */}
      <div style={{
        position: "absolute", top: -200, right: -200, width: 500, height: 500,
        borderRadius: "50%", background: `${colors.primary}06`, filter: "blur(80px)",
      }} />
      <div style={{
        position: "absolute", bottom: -150, left: -150, width: 400, height: 400,
        borderRadius: "50%", background: `${colors.accent}06`, filter: "blur(60px)",
      }} />

      {/* Section title */}
      <div
        style={{
          position: "absolute",
          top: 50,
          opacity: titleSpring,
          transform: `translateY(${titleY}px)`,
          textAlign: "center",
        }}
      >
        <div style={{
          fontSize: 14, fontWeight: 600, color: colors.accent,
          letterSpacing: 3, textTransform: "uppercase", marginBottom: 8,
        }}>
          Neler Yapabilirsiniz?
        </div>
        <h2
          style={{
            fontSize: 52,
            fontWeight: 900,
            color: colors.primaryDark,
            margin: 0,
          }}
        >
          Ozellikler
        </h2>
        <div
          style={{
            width: lineWidth,
            height: 4,
            background: `linear-gradient(90deg, ${colors.accent}, ${colors.primary})`,
            borderRadius: 2,
            margin: "14px auto 0",
          }}
        />
      </div>

      {/* Feature cards - 3x2 grid */}
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          gap: 16,
          justifyContent: "center",
          marginTop: 50,
          maxWidth: 1050,
        }}
      >
        {features.map((feature, i) => (
          <FeatureCard
            key={i}
            emoji={feature.emoji}
            title={feature.title}
            description={feature.description}
            delay={15 + i * 10}
            index={i}
            accentColor={feature.accentColor}
          />
        ))}
      </div>
    </AbsoluteFill>
  );
};
