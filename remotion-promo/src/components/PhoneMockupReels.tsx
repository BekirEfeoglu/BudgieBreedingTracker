import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets } from "../theme";

// Constants for reels phone dimensions
const PHONE_WIDTH = 430;
const PHONE_HEIGHT = 880;
const SCREEN_WIDTH = 408;
const SCREEN_HEIGHT = 858;

// ─── Simulated touch cursor with deterministic ripple ──────────
const TouchCursor: React.FC<{ x: number; y: number; clickFrame: number; visible: boolean }> = ({
  x,
  y,
  clickFrame,
  visible,
}) => {
  if (!visible || clickFrame < 0) return null;
  
  // Cursor scales down slightly when clicking
  const cursorScale = interpolate(clickFrame, [0, 4, 15], [1, 0.8, 1], { extrapolateRight: "clamp" });
  
  // Click ripple circles
  const ripple1Scale = interpolate(clickFrame, [0, 15], [0.8, 2.5], { extrapolateRight: "clamp" });
  const ripple1Opacity = interpolate(clickFrame, [0, 4, 15], [0, 0.8, 0], { extrapolateRight: "clamp" });

  const ripple2Scale = interpolate(clickFrame, [3, 18], [0.8, 2.2], { extrapolateRight: "clamp" });
  const ripple2Opacity = interpolate(clickFrame, [3, 7, 18], [0, 0.6, 0], { extrapolateRight: "clamp" });

  return (
    <div style={{
      position: "absolute", left: x - 18, top: y - 18,
      width: 36, height: 36, borderRadius: "50%",
      background: "radial-gradient(circle, rgba(255,255,255,0.45) 0%, rgba(255,255,255,0.15) 50%, transparent 70%)",
      boxShadow: "0 0 20px rgba(255,255,255,0.3)",
      zIndex: 100, pointerEvents: "none",
      transform: `scale(${cursorScale})`,
    }}>
      {/* Ripple 1 */}
      {clickFrame >= 0 && clickFrame <= 15 && (
        <div style={{
          position: "absolute", inset: 0, borderRadius: "50%",
          border: `2px solid ${colors.primary}`,
          transform: `scale(${ripple1Scale})`,
          opacity: ripple1Opacity,
        }} />
      )}
      {/* Ripple 2 */}
      {clickFrame >= 3 && clickFrame <= 18 && (
        <div style={{
          position: "absolute", inset: 0, borderRadius: "50%",
          border: `1.5px solid ${colors.budgieYellow}`,
          transform: `scale(${ripple2Scale})`,
          opacity: ripple2Opacity,
        }} />
      )}
    </div>
  );
};

// ─── Rich Notification popup ──────────────────────────────────
const NotificationPopup: React.FC<{
  emoji: string;
  title: string;
  body: string;
  show: boolean;
  slideProgress: number;
}> = ({ emoji, title, body, show, slideProgress }) => {
  if (!show && slideProgress <= 0) return null;
  const slideY = interpolate(slideProgress, [0, 1], [-90, 0]);
  return (
    <div style={{
      position: "absolute", top: 55, left: 16, right: 16, zIndex: 55,
      opacity: slideProgress, transform: `translateY(${slideY}px)`,
      backgroundColor: "rgba(26,26,29,0.92)", borderRadius: 18, padding: "12px 16px",
      border: `1px solid rgba(255,255,255,0.08)`,
      display: "flex", alignItems: "center", gap: 12,
      boxShadow: "0 10px 30px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.05)",
      backdropFilter: "blur(15px)",
    }}>
      <div style={{
        width: 38, height: 38, borderRadius: 10,
        background: `linear-gradient(135deg, ${colors.primary}25, ${colors.primary}08)`,
        display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20,
        border: `1px solid ${colors.primary}25`,
      }}>{emoji}</div>
      <div style={{ flex: 1, fontFamily: fonts.body }}>
        <div style={{ fontSize: 12.5, fontWeight: 800, color: colors.textPrimary }}>{title}</div>
        <div style={{ fontSize: 10, color: "rgba(255,255,255,0.5)", marginTop: 2 }}>{body}</div>
      </div>
      <div style={{ fontSize: 9, color: "rgba(255,255,255,0.35)", fontFamily: fonts.body }}>şimdi</div>
    </div>
  );
};

// ─── Bottom Nav ─────────────────────────────────────────────
const BottomNav: React.FC<{ activeIndex: number }> = ({ activeIndex }) => {
  const tabs = [
    { icon: "🏠", label: "Ana Sayfa" },
    { icon: "🐦", label: "Kuşlar" },
    { icon: "💑", label: "Üreme" },
    { icon: "📅", label: "Takvim" },
    { icon: "☰", label: "Diğer" },
  ];
  return (
    <div style={{
      position: "absolute", bottom: 0, left: 0, right: 0,
      display: "flex", justifyContent: "space-around", alignItems: "center",
      padding: "12px 0 26px", backgroundColor: colors.surface,
      borderTop: `1px solid ${colors.surfaceVariant}`,
    }}>
      {tabs.map((tab, i) => (
        <div key={i} style={{ textAlign: "center", flex: 1 }}>
          <span style={{ fontSize: 17, opacity: activeIndex === i ? 1 : 0.35 }}>{tab.icon}</span>
          <div style={{
            fontSize: 9, marginTop: 4,
            color: activeIndex === i ? colors.primary : colors.textSecondary,
            fontWeight: activeIndex === i ? 700 : 400,
            fontFamily: fonts.body,
          }}>{tab.label}</div>
          {activeIndex === i && (
            <div style={{
              width: 20, height: 2.5, borderRadius: 1.2, margin: "3px auto 0",
              backgroundColor: colors.primary, boxShadow: `0 0 6px ${colors.primary}`,
            }} />
          )}
        </div>
      ))}
    </div>
  );
};

// ─── Bird List Screen ────────────────────────────────────────
const BirdListScreen: React.FC<{ frame: number }> = ({ frame }) => {
  const birds = [
    { name: "Mavi",  gender: "Erkek", ring: "TR-2024-001", color: "#42A5F5", mutation: "Normal" },
    { name: "Sarı",  gender: "Dişi",  ring: "TR-2024-002", color: "#FFD54F", mutation: "Lutino" },
    { name: "Yeşil", gender: "Erkek", ring: "TR-2024-003", color: "#66BB6A", mutation: "Opalin" },
    { name: "Mor",   gender: "Dişi",  ring: "TR-2024-004", color: "#AB47BC", mutation: "Violet" },
  ];

  return (
    <div style={{ padding: "20px 18px", height: "100%", backgroundColor: colors.background, position: "relative" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12, paddingTop: 10 }}>
        <span style={{ fontSize: 13, color: colors.textSecondary, fontWeight: 700, fontFamily: fonts.body }}>9:41</span>
        <div style={{ display: "flex", gap: 4 }}>
          <div style={{ width: 16, height: 10, borderRadius: 3, border: `1px solid ${colors.textSecondary}`, position: "relative" }}>
            <div style={{ position: "absolute", inset: 1.5, borderRadius: 1.5, backgroundColor: colors.primary }} />
          </div>
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
        <h2 style={{ fontSize: 24, fontWeight: 800, color: colors.textPrimary, margin: 0, fontFamily: fonts.title }}>Kuşlarım</h2>
        <div style={{
          width: 36, height: 36, borderRadius: 11,
          background: `linear-gradient(135deg, ${colors.primary}25, ${colors.primary}10)`,
          display: "flex", alignItems: "center", justifyContent: "center",
          fontSize: 18, color: colors.primary, fontWeight: 700,
          border: `1px solid ${colors.primary}30`,
        }}>+</div>
      </div>
      <div style={{
        backgroundColor: colors.surface, borderRadius: 14, padding: "10px 14px",
        marginBottom: 16, fontSize: 13, color: colors.textSecondary,
        border: `1px solid ${colors.surfaceVariant}`, display: "flex", alignItems: "center", gap: 8,
        fontFamily: fonts.body,
      }}>
        <span style={{ opacity: 0.5 }}>🔍</span> Kuş ara...
      </div>

      {birds.map((bird, i) => {
        const d = 4 + i * 4;
        const p = Math.min(1, Math.max(0, (frame - d) / 8));
        return (
          <div key={i} style={{
            opacity: p, transform: `translateX(${(1 - p) * 30}px) scale(${0.95 + p * 0.05})`,
            display: "flex", alignItems: "center", gap: 12,
            padding: "12px 14px", backgroundColor: colors.surface,
            borderRadius: 16, marginBottom: 8, border: `1px solid ${colors.surfaceVariant}`,
          }}>
            <div style={{
              width: 42, height: 42, borderRadius: 11,
              background: `linear-gradient(135deg, ${bird.color}30, ${bird.color}10)`,
              display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20,
            }}>🐦</div>
            <div style={{ flex: 1, fontFamily: fonts.body }}>
              <div style={{ fontSize: 15, fontWeight: 700, color: colors.textPrimary }}>{bird.name}</div>
              <div style={{ fontSize: 11, color: colors.textSecondary, marginTop: 2 }}>{bird.ring} · {bird.gender}</div>
            </div>
            <div style={{
              fontSize: 10, fontWeight: 700, color: bird.color,
              backgroundColor: `${bird.color}12`, borderRadius: 6, padding: "3px 8px",
              fontFamily: fonts.body,
            }}>{bird.mutation}</div>
          </div>
        );
      })}

      <BottomNav activeIndex={1} />
    </div>
  );
};

// ─── Stats Screen ────────────────────────────────────────────
const StatsScreen: React.FC<{ frame: number }> = ({ frame }) => {
  const barData = [65, 82, 45, 90, 73, 88, 55];
  const months = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem"];

  return (
    <div style={{ padding: "20px 18px", height: "100%", backgroundColor: colors.background, position: "relative" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12, paddingTop: 10 }}>
        <span style={{ fontSize: 13, color: colors.textSecondary, fontWeight: 700, fontFamily: fonts.body }}>9:41</span>
      </div>
      <h2 style={{ fontSize: 24, fontWeight: 800, color: colors.textPrimary, margin: "0 0 16px", fontFamily: fonts.title }}>İstatistikler</h2>

      <div style={{ display: "flex", gap: 7, marginBottom: 16 }}>
        {[
          { label: "Toplam Kuş", value: 24, icon: "🐦", color: colors.primary },
          { label: "Başarı Oranı", value: 78, icon: "📈", color: colors.accent, suffix: "%" },
          { label: "Yeni Yavru", value: 12, icon: "🐣", color: colors.budgieYellow },
        ].map((stat, i) => {
          const p = Math.min(1, Math.max(0, (frame - 4 - i * 3) / 10));
          const countUp = Math.round(stat.value * p);
          return (
            <div key={i} style={{
              flex: 1, backgroundColor: colors.surface, borderRadius: 14, padding: "12px 6px",
              textAlign: "center", border: `1px solid ${colors.surfaceVariant}`,
              opacity: p, transform: `scale(${0.85 + p * 0.15})`,
            }}>
              <div style={{ fontSize: 16, marginBottom: 4 }}>{stat.icon}</div>
              <div style={{ fontSize: 20, fontWeight: 800, color: stat.color, fontFamily: fonts.title }}>
                {stat.suffix ? `%${countUp}` : countUp}
              </div>
              <div style={{ fontSize: 9, color: colors.textSecondary, marginTop: 3, fontWeight: 600, fontFamily: fonts.body }}>{stat.label}</div>
            </div>
          );
        })}
      </div>

      <div style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 14, border: `1px solid ${colors.surfaceVariant}` }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: colors.textPrimary, marginBottom: 12, fontFamily: fonts.title }}>Aylık Üreme Başarısı</div>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height: 110 }}>
          {barData.map((val, i) => {
            const bp = Math.min(1, Math.max(0, (frame - 12 - i * 2) / 10));
            return (
              <div key={i} style={{ flex: 1, textAlign: "center" }}>
                <div style={{
                  height: val * bp * 0.9,
                  background: i === 3
                    ? `linear-gradient(to top, ${colors.accent}, ${colors.accent}80)`
                    : `linear-gradient(to top, ${colors.primary}, ${colors.primary}60)`,
                  borderRadius: "4px 4px 0 0",
                  boxShadow: i === 3 ? `0 0 10px ${colors.accent}40` : undefined,
                }} />
                <div style={{ fontSize: 9, color: colors.textSecondary, marginTop: 5, fontFamily: fonts.body }}>{months[i]}</div>
              </div>
            );
          })}
        </div>
      </div>
      <BottomNav activeIndex={4} />
    </div>
  );
};

// ─── Genetics Screen ─────────────────────────────────────────
const GeneticsScreen: React.FC<{ frame: number }> = ({ frame }) => {
  const punnettData = [["", "G", "g"], ["G", "GG", "Gg"], ["g", "Gg", "gg"]];

  return (
    <div style={{ padding: "20px 18px", height: "100%", backgroundColor: colors.background, position: "relative" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12, paddingTop: 10 }}>
        <span style={{ fontSize: 13, color: colors.textSecondary, fontWeight: 700, fontFamily: fonts.body }}>9:41</span>
      </div>
      <h2 style={{ fontSize: 24, fontWeight: 800, color: colors.textPrimary, margin: "0 0 14px", fontFamily: fonts.title }}>Genetik</h2>

      <div style={{ display: "flex", gap: 10, marginBottom: 14 }}>
        {[
          { label: "Baba", emoji: "🐦", color: colors.budgieBlue, genotype: "Gg" },
          { label: "Anne", emoji: "🐦", color: "#E91E63", genotype: "Gg" },
        ].map((parent, i) => {
          const p = Math.min(1, Math.max(0, (frame - 4 - i * 5) / 8));
          return (
            <div key={i} style={{
              flex: 1, display: "flex", alignItems: "center", gap: 8,
              backgroundColor: colors.surface, borderRadius: 14, padding: "10px 12px",
              border: `1px solid ${parent.color}30`,
              opacity: p, transform: `translateY(${(1 - p) * 10}px)`,
            }}>
              <span style={{ fontSize: 20 }}>{parent.emoji}</span>
              <div style={{ fontFamily: fonts.body }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: colors.textPrimary }}>{parent.label}</div>
                <div style={{ fontSize: 9, color: parent.color, fontWeight: 600, marginTop: 1 }}>{parent.genotype} (Taşıyıcı)</div>
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ textAlign: "center", marginBottom: 8 }}>
        <div style={{
          display: "inline-block", fontSize: 16, color: colors.textSecondary,
          opacity: interpolate(frame, [12, 18], [0, 0.6], { extrapolateRight: "clamp" }),
          transform: `translateY(${interpolate(frame, [12, 18], [6, 0], { extrapolateRight: "clamp" })}px)`,
        }}>▼</div>
      </div>

      <div style={{ backgroundColor: colors.surface, borderRadius: 16, padding: 14, border: `1px solid ${colors.surfaceVariant}` }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: colors.textPrimary, marginBottom: 10, fontFamily: fonts.title }}>Punnett Karesi</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 5 }}>
          {punnettData.flat().map((cell, idx) => {
            const row = Math.floor(idx / 3);
            const col = idx % 3;
            const isHeader = row === 0 || col === 0;
            const cellDelay = 10 + (row * 3 + col) * 3;
            const p = Math.min(1, Math.max(0, (frame - cellDelay) / 7));
            const bgColor = isHeader ? `${colors.budgieTeal}15`
              : cell === "gg" ? `${colors.accent}20`
              : cell === "GG" ? `${colors.primary}20`
              : `${colors.budgieYellow}15`;
            return (
              <div key={idx} style={{
                opacity: isHeader ? 1 : p,
                transform: `scale(${isHeader ? 1 : 0.7 + p * 0.3}) rotate(${isHeader ? 0 : (1 - p) * 10}deg)`,
                padding: "11px 0", textAlign: "center",
                fontSize: isHeader ? 12 : 14, fontWeight: isHeader ? 700 : 600,
                color: isHeader ? colors.budgieTeal : colors.textPrimary,
                backgroundColor: bgColor, borderRadius: 8,
                fontFamily: fonts.body,
              }}>{cell}</div>
            );
          })}
        </div>
        <div style={{
          marginTop: 10, padding: "7px 12px",
          background: `linear-gradient(90deg, ${colors.primary}12, ${colors.accent}12)`,
          borderRadius: 8, display: "flex", justifyContent: "center", gap: 10,
          opacity: interpolate(frame, [35, 42], [0, 1], { extrapolateRight: "clamp" }),
        }}>
          {[
            { label: "GG", pct: 25, color: colors.primary },
            { label: "Gg", pct: 50, color: colors.budgieYellow },
            { label: "gg", pct: 25, color: colors.accent },
          ].map((r, i) => (
            <span key={i} style={{ fontSize: 10, fontWeight: 700, color: r.color, fontFamily: fonts.body }}>
              %{r.pct} {r.label}
            </span>
          ))}
        </div>
      </div>
      <BottomNav activeIndex={-1} />
    </div>
  );
};

// ─── Main Phone Demo Scene ──────────────────────────────────
export const PhoneDemoSceneReels: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const phoneEntrance = spring({ frame, fps, config: springPresets.smooth });
  const phoneY = interpolate(phoneEntrance, [0, 1], [150, 0]);

  // Screen switching duration
  const dur = 90;
  const screenIndex = frame < dur ? 0 : frame < dur * 2 ? 1 : 2;
  const screenFrame = frame < dur ? frame : frame < dur * 2 ? frame - dur : frame - dur * 2;

  // 3D perspective
  const tiltX = interpolate(frame, [0, 50, 70], [15, 3, 0], { extrapolateRight: "clamp" });
  const tiltY = interpolate(frame, [0, 50, 70], [-10, -1.5, 0], { extrapolateRight: "clamp" });

  // Continuous subtle float
  const floatY = frame > 70 ? Math.sin((frame - 70) * 0.035) * 6 : 0;
  const floatRotate = frame > 70 ? Math.sin((frame - 70) * 0.02) * 0.8 : 0;

  // 3D transition physical bounce (inertia/momentum effect at screen changes)
  const bounceScale = 1 - (
    interpolate(spring({ frame: Math.max(0, frame - dur), fps, config: springPresets.snappy }), [0, 0.2, 1], [0, 0.035, 0]) +
    interpolate(spring({ frame: Math.max(0, frame - dur * 2), fps, config: springPresets.snappy }), [0, 0.2, 1], [0, 0.035, 0])
  );
  const bounceRotateY = (
    interpolate(spring({ frame: Math.max(0, frame - dur), fps, config: springPresets.snappy }), [0, 0.2, 1], [0, -6, 0]) +
    interpolate(spring({ frame: Math.max(0, frame - dur * 2), fps, config: springPresets.snappy }), [0, 0.2, 1], [0, 6, 0])
  );
  const bounceTranslateX = (
    interpolate(spring({ frame: Math.max(0, frame - dur), fps, config: springPresets.snappy }), [0, 0.2, 1], [0, -12, 0]) +
    interpolate(spring({ frame: Math.max(0, frame - dur * 2), fps, config: springPresets.snappy }), [0, 0.2, 1], [0, 12, 0])
  );

  const screenLabels = ["Kuş Yönetimi", "İstatistikler", "Genetik Hesaplama"];
  const titleOpacity = interpolate(frame, [0, 12], [0, 1], { extrapolateRight: "clamp" });

  // Screen transition offset
  const getOffset = (target: number) => {
    if (screenIndex === target) {
      const transFrame = target * dur;
      if (frame - transFrame < 10 && target > 0) {
        return interpolate(frame - transFrame, [0, 10], [SCREEN_WIDTH, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
      }
      return 0;
    }
    return screenIndex > target ? -SCREEN_WIDTH : SCREEN_WIDTH;
  };

  // ── Notification Popup 1 & 2 ──
  const showNotif1 = frame >= 8 && frame < 52;
  const notif1Progress = spring({ frame: Math.max(0, frame - 8), fps, config: springPresets.smooth });
  const notif1FadeOut = spring({ frame: Math.max(0, frame - 42), fps, config: springPresets.smooth });
  const notif1Slide = interpolate(notif1Progress - notif1FadeOut, [0, 1], [0, 1]);

  const showNotif2 = frame >= 100 && frame < 155;
  const notif2Progress = spring({ frame: Math.max(0, frame - 100), fps, config: springPresets.smooth });
  const notif2FadeOut = spring({ frame: Math.max(0, frame - 145), fps, config: springPresets.smooth });
  const notif2Slide = interpolate(notif2Progress - notif2FadeOut, [0, 1], [0, 1]);

  // ── Touch Cursor coordinates & click frames ──
  let cursorX = 0;
  let cursorY = 0;
  let cursorVisible = false;
  let clickFrame = -1;

  if (frame >= 30 && frame < 48) {
    // Click on Notif 1 (dismiss/open)
    cursorVisible = true;
    cursorX = interpolate(frame, [30, 42], [320, 250], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    cursorY = interpolate(frame, [30, 42], [700, 110], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    if (frame >= 42) clickFrame = frame - 42;
  } else if (frame >= 72 && frame < 90) {
    // Click on Stats tab
    cursorVisible = true;
    cursorX = interpolate(frame, [72, 85], [250, 326], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    cursorY = interpolate(frame, [72, 85], [110, 830], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    if (frame >= 85) clickFrame = frame - 85;
  } else if (frame >= 148 && frame < 172) {
    // Click on Genetics tab
    cursorVisible = true;
    cursorX = interpolate(frame, [148, 168], [326, 204], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    cursorY = interpolate(frame, [148, 168], [830, 830], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    if (frame >= 168) clickFrame = frame - 168;
  } else if (frame >= 205 && frame < 225) {
    // Click on genetics calculation cell
    cursorVisible = true;
    cursorX = interpolate(frame, [205, 220], [204, 280], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    cursorY = interpolate(frame, [205, 220], [830, 430], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
    if (frame >= 220) clickFrame = frame - 220;
  }

  return (
    <AbsoluteFill style={{
      background: `radial-gradient(ellipse at 50% 45%, ${colors.gradient.mid}30 0%, ${colors.background} 65%)`,
      justifyContent: "center", alignItems: "center", overflow: "hidden",
    }}>
      {/* Animated grid background */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px)`,
        backgroundSize: "70px 70px",
        transform: `translateY(${frame * 0.2}px)`,
      }} />

      {/* Ambient orbs */}
      {[0, 1, 2].map((i) => (
        <div key={i} style={{
          position: "absolute",
          width: 350 + i * 80, height: 350 + i * 80, borderRadius: "50%",
          background: `radial-gradient(circle, ${[colors.primary, colors.accent, colors.budgieYellow][i]}08 0%, transparent 60%)`,
          transform: `translate(${Math.sin(frame * 0.01 + i * 2.5) * 80}px, ${Math.cos(frame * 0.012 + i) * 80}px)`,
          filter: "blur(35px)",
        }} />
      ))}

      {/* Title */}
      <div style={{
        position: "absolute", top: 140, opacity: titleOpacity, textAlign: "center",
        fontFamily: fonts.title, zIndex: 10,
      }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 8,
          fontSize: 14, fontWeight: 700, color: colors.accent,
          letterSpacing: 4, textTransform: "uppercase", marginBottom: 12,
        }}>
          <div style={{ width: 25, height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
          Uygulama Önizleme
          <div style={{ width: 25, height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
        </div>
        <h2 style={{ fontSize: 44, fontWeight: 900, color: colors.textOnDark, margin: 0, textShadow: `0 0 25px ${colors.primary}20` }}>
          {screenLabels[screenIndex]}
        </h2>
      </div>

      {/* Phone container */}
      <div style={{
        transform: `
          scale(${phoneEntrance * bounceScale * 0.95})
          translateY(${phoneY + floatY}px)
          translateX(${bounceTranslateX}px)
          perspective(1000px)
          rotateX(${tiltX}deg)
          rotateY(${tiltY + floatRotate + bounceRotateY}deg)
        `,
        marginTop: 120,
        position: "relative",
      }}>
        {/* Shadow */}
        <div style={{
          position: "absolute", bottom: -60, left: 35, right: 35, height: 100,
          background: "radial-gradient(ellipse, rgba(0,0,0,0.55) 0%, transparent 70%)", filter: "blur(30px)",
        }} />

        {/* Phone body */}
        <div style={{
          width: PHONE_WIDTH, height: PHONE_HEIGHT, backgroundColor: "#111", borderRadius: 48, padding: 11,
          boxShadow: `0 30px 80px rgba(0,0,0,0.65), inset 0 1px 2px rgba(255,255,255,0.25), 0 0 0 3px #333, 0 0 70px ${colors.primary}08`,
          position: "relative",
        }}>
          {/* Glass reflection */}
          <div style={{
            position: "absolute", inset: 0, borderRadius: 48,
            background: "linear-gradient(120deg, rgba(255,255,255,0.08) 0%, transparent 45%)",
            pointerEvents: "none", zIndex: 50,
          }} />

          {/* Dynamic Island */}
          <div style={{
            position: "absolute", top: 11, left: "50%", transform: "translateX(-50%)",
            width: 140, height: 32, backgroundColor: "#000", borderRadius: 20,
            zIndex: 10, display: "flex", justifyContent: "center", alignItems: "center",
          }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", backgroundColor: "#161616", border: "1px solid #252525" }} />
          </div>

          {/* Screen */}
          <div style={{
            width: SCREEN_WIDTH, height: SCREEN_HEIGHT, borderRadius: 38, overflow: "hidden",
            position: "relative", backgroundColor: colors.background,
          }}>
            {[0, 1, 2].map((idx) => {
              const offset = getOffset(idx);
              if (Math.abs(offset) >= SCREEN_WIDTH && screenIndex !== idx) return null;
              return (
                <div key={idx} style={{
                  position: "absolute", inset: 0,
                  transform: `translateX(${offset}px)`,
                  opacity: screenIndex === idx ? 1 : 0,
                }}>
                  {idx === 0 && <BirdListScreen frame={screenIndex === 0 ? screenFrame : 0} />}
                  {idx === 1 && <StatsScreen frame={screenIndex === 1 ? screenFrame : 0} />}
                  {idx === 2 && <GeneticsScreen frame={screenIndex === 2 ? screenFrame : 0} />}
                </div>
              );
            })}
          </div>

          {/* Notification 1 */}
          <NotificationPopup
            emoji="🥚"
            title="Kuluçka Hatırlatması"
            body="Yumurta çevirme zamanı! (14:00)"
            show={showNotif1}
            slideProgress={notif1Slide}
          />

          {/* Notification 2 */}
          <NotificationPopup
            emoji="🐣"
            title="Yavru Yumurtadan Çıktı!"
            body="Mavi & Sarı çiftinin 3. yumurtası çatladı!"
            show={showNotif2}
            slideProgress={notif2Slide}
          />

          {/* Interactive touch cursor overlay */}
          <TouchCursor x={cursorX} y={cursorY} clickFrame={clickFrame} visible={cursorVisible} />

          {/* Home indicator */}
          <div style={{
            position: "absolute", bottom: 10, left: "50%", transform: "translateX(-50%)",
            width: 140, height: 4.5, backgroundColor: "rgba(255,255,255,0.3)", borderRadius: 2.2, zIndex: 50,
          }} />
        </div>
      </div>

      {/* Screen dots */}
      <div style={{ position: "absolute", bottom: 120, display: "flex", gap: 10, alignItems: "center" }}>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{
            width: screenIndex === i ? 28 : 8, height: 8, borderRadius: 4,
            backgroundColor: screenIndex === i ? colors.primary : `${colors.textSecondary}35`,
            boxShadow: screenIndex === i ? `0 0 10px ${colors.primary}60` : "none",
            transition: "width 0.2s, background-color 0.2s",
          }} />
        ))}
      </div>
    </AbsoluteFill>
  );
};
