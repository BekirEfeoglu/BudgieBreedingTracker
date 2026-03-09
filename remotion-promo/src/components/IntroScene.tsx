import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, springPresets } from "../theme";
import { BudgieIcon } from "./BudgieIcon";

export const IntroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Logo entrance with bounce
  const logoScale = spring({ frame, fps, config: springPresets.bouncy });
  const logoRotate = interpolate(logoScale, [0, 1], [-15, 0]);

  // Title letter-by-letter
  const titleText = "BudgieBreeder";
  const titleStart = 25;

  // Subtitle fade
  const subtitleOpacity = interpolate(frame, [50, 70], [0, 1], {
    extrapolateRight: "clamp",
  });
  const subtitleY = spring({
    frame: Math.max(0, frame - 50),
    fps,
    config: springPresets.gentle,
  });

  // Tagline
  const taglineOpacity = interpolate(frame, [70, 90], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Background animated gradient rotation
  const gradientAngle = interpolate(frame, [0, 150], [135, 155]);

  // Floating orbs
  const orbCount = 6;

  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(${gradientAngle}deg, #0A2E0F 0%, ${colors.gradient.start} 30%, ${colors.gradient.mid} 60%, ${colors.gradient.end} 100%)`,
        justifyContent: "center",
        alignItems: "center",
        overflow: "hidden",
      }}
    >
      {/* Large blurred background orbs */}
      {[...Array(orbCount)].map((_, i) => {
        const speed = 0.02 + i * 0.005;
        const radius = 200 + i * 80;
        const x = Math.sin(frame * speed + i * 1.2) * radius;
        const y = Math.cos(frame * speed + i * 0.9) * (radius * 0.6);
        const size = 300 + i * 100;
        const hue = [120, 140, 80, 160, 100, 60][i];
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              width: size,
              height: size,
              borderRadius: "50%",
              background: `radial-gradient(circle, hsla(${hue}, 70%, 45%, 0.12) 0%, transparent 70%)`,
              transform: `translate(${x}px, ${y}px)`,
              filter: "blur(60px)",
            }}
          />
        );
      })}

      {/* Mesh grid pattern */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          backgroundImage: `
            linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px)
          `,
          backgroundSize: "60px 60px",
          transform: `perspective(800px) rotateX(60deg) translateY(${-50 + frame * 0.5}px)`,
          transformOrigin: "center top",
          opacity: 0.6,
        }}
      />

      {/* Sparkle particles */}
      {[...Array(15)].map((_, i) => {
        const life = (frame + i * 20) % 100;
        const startX = (i * 173) % 1920 - 960;
        const startY = (i * 251) % 1080 - 540;
        const opacity = interpolate(life, [0, 15, 70, 100], [0, 0.8, 0.8, 0]);
        const scale = interpolate(life, [0, 15, 100], [0, 1, 0.3]);
        const drift = life * 0.3;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              width: 4,
              height: 4,
              borderRadius: "50%",
              backgroundColor: i % 3 === 0 ? colors.budgieYellow : "rgba(255,255,255,0.7)",
              opacity,
              transform: `translate(${startX}px, ${startY - drift}px) scale(${scale})`,
              boxShadow: i % 3 === 0
                ? `0 0 8px ${colors.budgieYellow}`
                : "0 0 6px rgba(255,255,255,0.5)",
            }}
          />
        );
      })}

      {/* Logo with glow */}
      <div
        style={{
          transform: `scale(${logoScale}) rotate(${logoRotate}deg)`,
          marginBottom: 24,
          position: "relative",
        }}
      >
        {/* Glow ring behind logo */}
        <div
          style={{
            position: "absolute",
            inset: -30,
            borderRadius: "50%",
            background: `radial-gradient(circle, rgba(255,213,79,${0.2 + Math.sin(frame * 0.08) * 0.1}) 0%, transparent 60%)`,
            filter: "blur(20px)",
          }}
        />
        <BudgieIcon size={180} />
      </div>

      {/* Title with letter animation */}
      <div
        style={{
          display: "flex",
          justifyContent: "center",
          marginBottom: 8,
        }}
      >
        {titleText.split("").map((char, i) => {
          const charDelay = titleStart + i * 2;
          const charSpring = spring({
            frame: Math.max(0, frame - charDelay),
            fps,
            config: springPresets.snappy,
          });
          const y = interpolate(charSpring, [0, 1], [40, 0]);
          const rotate = interpolate(charSpring, [0, 1], [20, 0]);

          return (
            <span
              key={i}
              style={{
                fontSize: 78,
                fontWeight: 900,
                color: colors.textOnDark,
                display: "inline-block",
                transform: `translateY(${y}px) rotate(${rotate}deg)`,
                opacity: charSpring,
                textShadow: "0 4px 30px rgba(0,0,0,0.4), 0 0 60px rgba(76,175,80,0.3)",
                letterSpacing: i === 6 ? 2 : -1, // Space before "Breeder"
              }}
            >
              {char}
            </span>
          );
        })}
      </div>

      {/* Subtitle */}
      <div
        style={{
          opacity: subtitleOpacity,
          transform: `translateY(${interpolate(subtitleY, [0, 1], [20, 0])}px)`,
          marginTop: 4,
        }}
      >
        <p
          style={{
            fontSize: 26,
            color: colors.primaryLight,
            margin: 0,
            fontWeight: 400,
            letterSpacing: 6,
            textTransform: "uppercase",
          }}
        >
          Muhabbet Kusu Ureme Takip
        </p>
      </div>

      {/* Tagline */}
      <div
        style={{
          opacity: taglineOpacity,
          marginTop: 28,
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 16,
          }}
        >
          {["Offline-First", "3 Dil", "Sifrelenmis"].map((tag, i) => (
            <React.Fragment key={i}>
              {i > 0 && (
                <div
                  style={{
                    width: 4,
                    height: 4,
                    borderRadius: "50%",
                    backgroundColor: colors.accent,
                  }}
                />
              )}
              <span
                style={{
                  fontSize: 16,
                  color: "rgba(255,255,255,0.6)",
                  fontWeight: 500,
                  letterSpacing: 1,
                }}
              >
                {tag}
              </span>
            </React.Fragment>
          ))}
        </div>
      </div>
    </AbsoluteFill>
  );
};
