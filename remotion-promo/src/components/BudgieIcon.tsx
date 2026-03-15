import React from "react";
import { Img, staticFile, useCurrentFrame, interpolate } from "remotion";

interface BudgieIconProps {
  size?: number;
  animated?: boolean;
}

export const BudgieIcon: React.FC<BudgieIconProps> = ({ size = 120, animated = true }) => {
  const frame = useCurrentFrame();

  // Animated shine sweep
  const shineX = animated
    ? interpolate((frame % 120), [0, 60, 119], [-100, 150, 150], { extrapolateRight: "clamp" })
    : -100;

  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: size * 0.22,
        overflow: "hidden",
        boxShadow: `0 8px 40px rgba(0,0,0,0.35), 0 2px 8px rgba(0,0,0,0.2), 0 0 60px rgba(20,241,149,0.1)`,
        position: "relative",
      }}
    >
      <Img
        src={staticFile("budgie-icon.png")}
        style={{ width: "100%", height: "100%", objectFit: "cover" }}
      />
      {/* Static glass overlay */}
      <div
        style={{
          position: "absolute",
          top: 0, left: 0, right: 0,
          height: "45%",
          background: "linear-gradient(180deg, rgba(255,255,255,0.2) 0%, transparent 100%)",
          borderRadius: `${size * 0.22}px ${size * 0.22}px 0 0`,
          pointerEvents: "none",
        }}
      />
      {/* Animated shine sweep */}
      {animated && (
        <div
          style={{
            position: "absolute",
            top: 0, bottom: 0,
            left: `${shineX}%`,
            width: "30%",
            background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.25), transparent)",
            transform: "skewX(-20deg)",
            pointerEvents: "none",
          }}
        />
      )}
    </div>
  );
};
