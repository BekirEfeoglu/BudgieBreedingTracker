import React from "react";
import { Img, staticFile } from "remotion";

interface BudgieIconProps {
  size?: number;
}

export const BudgieIcon: React.FC<BudgieIconProps> = ({ size = 120 }) => {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: size * 0.22,
        overflow: "hidden",
        boxShadow: `0 8px 40px rgba(0,0,0,0.35), 0 2px 8px rgba(0,0,0,0.2)`,
        position: "relative",
      }}
    >
      <Img
        src={staticFile("budgie-icon.png")}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
        }}
      />
      {/* Shine overlay */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: "45%",
          background:
            "linear-gradient(180deg, rgba(255,255,255,0.25) 0%, transparent 100%)",
          borderRadius: `${size * 0.22}px ${size * 0.22}px 0 0`,
          pointerEvents: "none",
        }}
      />
    </div>
  );
};
