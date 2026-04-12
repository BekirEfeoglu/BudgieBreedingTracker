import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { colors, fonts, springPresets, seededRandom } from "../theme";

// ─── Simulated touch cursor ──────────────────────────────────
const TouchCursor: React.FC<{ x: number; y: number; visible: boolean }> = ({ x, y, visible }) => {
  if (!visible) return null;
  return (
    <div style={{
      position: "absolute", left: x - 12, top: y - 12,
      width: 24, height: 24, borderRadius: "50%",
      background: "radial-gradient(circle, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0.1) 50%, transparent 70%)",
      boxShadow: "0 0 15px rgba(255,255,255,0.2)",
      zIndex: 60, pointerEvents: "none",
    }} />
  );
};

// ─── Notification popup ──────────────────────────────────────
const NotificationPopup: React.FC<{ frame: number; delay: number }> = ({ frame, delay }) => {
  const elapsed = frame - delay;
  if (elapsed < 0 || elapsed > 50) return null;
  const progress = interpolate(elapsed, [0, 8, 40, 50], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const slideY = interpolate(elapsed, [0, 8], [-30, 0], { extrapolateRight: "clamp" });
  return (
    <div style={{
      position: "absolute", top: 36, left: 10, right: 10, zIndex: 55,
      opacity: progress, transform: `translateY(${slideY}px)`,
      backgroundColor: colors.surface, borderRadius: 12, padding: "8px 10px",
      border: `1px solid ${colors.primary}30`,
      display: "flex", alignItems: "center", gap: 8,
      boxShadow: "0 4px 20px rgba(0,0,0,0.4)",
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 8,
        background: `linear-gradient(135deg, ${colors.primary}30, ${colors.primary}10)`,
        display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14,
      }}>🥚</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 9, fontWeight: 700, color: colors.textPrimary }}>Kuluçka Hatırlatma</div>
        <div style={{ fontSize: 7, color: colors.textSecondary }}>Yumurta çevirme zamanı! (14:00)</div>
      </div>
      <div style={{ fontSize: 7, color: colors.textSecondary }}>şimdi</div>
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
      padding: "6px 0 10px", backgroundColor: colors.surface,
      borderTop: `1px solid ${colors.surfaceVariant}`,
    }}>
      {tabs.map((tab, i) => (
        <div key={i} style={{ textAlign: "center", flex: 1 }}>
          <span style={{ fontSize: 13, opacity: activeIndex === i ? 1 : 0.35 }}>{tab.icon}</span>
          <div style={{
            fontSize: 6.5, marginTop: 1,
            color: activeIndex === i ? colors.primary : colors.textSecondary,
            fontWeight: activeIndex === i ? 700 : 400,
          }}>{tab.label}</div>
          {activeIndex === i && (
            <div style={{
              width: 16, height: 2, borderRadius: 1, margin: "2px auto 0",
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
    <div style={{ padding: 14, height: "100%", backgroundColor: colors.background, position: "relative" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, paddingTop: 4 }}>
        <span style={{ fontSize: 10, color: colors.textSecondary, fontWeight: 600 }}>9:41</span>
        <div style={{ display: "flex", gap: 3 }}>
          <div style={{ width: 12, height: 8, borderRadius: 2, border: `1px solid ${colors.textSecondary}`, position: "relative" }}>
            <div style={{ position: "absolute", inset: 1, borderRadius: 1, backgroundColor: colors.primary }} />
          </div>
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
        <h2 style={{ fontSize: 19, fontWeight: 800, color: colors.textPrimary, margin: 0 }}>Kuşlarım</h2>
        <div style={{
          width: 30, height: 30, borderRadius: 10,
          background: `linear-gradient(135deg, ${colors.primary}25, ${colors.primary}10)`,
          display: "flex", alignItems: "center", justifyContent: "center",
          fontSize: 14, color: colors.primary, fontWeight: 700,
          border: `1px solid ${colors.primary}30`,
        }}>+</div>
      </div>
      <div style={{
        backgroundColor: colors.surface, borderRadius: 10, padding: "7px 10px",
        marginBottom: 10, fontSize: 10, color: colors.textSecondary,
        border: `1px solid ${colors.surfaceVariant}`, display: "flex", alignItems: "center", gap: 5,
      }}>
        <span style={{ opacity: 0.5 }}>🔍</span> Kuş ara...
      </div>

      {birds.map((bird, i) => {
        const d = 6 + i * 4;
        const p = Math.min(1, Math.max(0, (frame - d) / 8));
        return (
          <div key={i} style={{
            opacity: p, transform: `translateX(${(1 - p) * 25}px) scale(${0.95 + p * 0.05})`,
            display: "flex", alignItems: "center", gap: 9,
            padding: "9px 10px", backgroundColor: colors.surface,
            borderRadius: 11, marginBottom: 5, border: `1px solid ${colors.surfaceVariant}`,
          }}>
            <div style={{
              width: 34, height: 34, borderRadius: 9,
              background: `linear-gradient(135deg, ${bird.color}30, ${bird.color}10)`,
              display: "flex", alignItems: "center", justifyContent: "center", fontSize: 15,
            }}>🐦</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: colors.textPrimary }}>{bird.name}</div>
              <div style={{ fontSize: 8, color: colors.textSecondary }}>{bird.ring} · {bird.gender}</div>
            </div>
            <div style={{
              fontSize: 7.5, fontWeight: 700, color: bird.color,
              backgroundColor: `${bird.color}12`, borderRadius: 4, padding: "2px 6px",
            }}>{bird.mutation}</div>
          </div>
        );
      })}

      <NotificationPopup frame={frame} delay={35} />
      <TouchCursor x={250} y={180} visible={frame > 20 && frame < 30} />
      <BottomNav activeIndex={1} />
    </div>
  );
};

// ─── Stats Screen ────────────────────────────────────────────
const StatsScreen: React.FC<{ frame: number }> = ({ frame }) => {
  const barData = [65, 82, 45, 90, 73, 88, 55];
  const months = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem"];

  return (
    <div style={{ padding: 14, height: "100%", backgroundColor: colors.background, position: "relative" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, paddingTop: 4 }}>
        <span style={{ fontSize: 10, color: colors.textSecondary, fontWeight: 600 }}>9:41</span>
      </div>
      <h2 style={{ fontSize: 19, fontWeight: 800, color: colors.textPrimary, margin: "0 0 12px" }}>İstatistikler</h2>

      <div style={{ display: "flex", gap: 5, marginBottom: 12 }}>
        {[
          { label: "Toplam Kuş", value: 24, icon: "🐦", color: colors.primary },
          { label: "Başarı", value: 78, icon: "📈", color: colors.accent, suffix: "%" },
          { label: "Yavru", value: 12, icon: "🐣", color: colors.budgieYellow },
        ].map((stat, i) => {
          const p = Math.min(1, Math.max(0, (frame - 6 - i * 3) / 10));
          const countUp = Math.round(stat.value * p);
          return (
            <div key={i} style={{
              flex: 1, backgroundColor: colors.surface, borderRadius: 10, padding: "8px 6px",
              textAlign: "center", border: `1px solid ${colors.surfaceVariant}`,
              opacity: p, transform: `scale(${0.85 + p * 0.15})`,
            }}>
              <div style={{ fontSize: 12, marginBottom: 3 }}>{stat.icon}</div>
              <div style={{ fontSize: 16, fontWeight: 800, color: stat.color }}>
                {stat.suffix ? `%${countUp}` : countUp}
              </div>
              <div style={{ fontSize: 6.5, color: colors.textSecondary, marginTop: 1, fontWeight: 600 }}>{stat.label}</div>
            </div>
          );
        })}
      </div>

      <div style={{ backgroundColor: colors.surface, borderRadius: 11, padding: 10, border: `1px solid ${colors.surfaceVariant}` }}>
        <div style={{ fontSize: 10, fontWeight: 700, color: colors.textPrimary, marginBottom: 8 }}>Aylık Üreme Başarısı</div>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 4, height: 70 }}>
          {barData.map((val, i) => {
            const bp = Math.min(1, Math.max(0, (frame - 15 - i * 2) / 10));
            return (
              <div key={i} style={{ flex: 1, textAlign: "center" }}>
                <div style={{
                  height: val * bp * 0.7,
                  background: i === 3
                    ? `linear-gradient(to top, ${colors.accent}, ${colors.accent}80)`
                    : `linear-gradient(to top, ${colors.primary}, ${colors.primary}60)`,
                  borderRadius: "3px 3px 0 0",
                  boxShadow: i === 3 ? `0 0 8px ${colors.accent}40` : undefined,
                }} />
                <div style={{ fontSize: 6.5, color: colors.textSecondary, marginTop: 2 }}>{months[i]}</div>
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
    <div style={{ padding: 14, height: "100%", backgroundColor: colors.background, position: "relative" }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, paddingTop: 4 }}>
        <span style={{ fontSize: 10, color: colors.textSecondary, fontWeight: 600 }}>9:41</span>
      </div>
      <h2 style={{ fontSize: 19, fontWeight: 800, color: colors.textPrimary, margin: "0 0 10px" }}>Genetik</h2>

      <div style={{ display: "flex", gap: 7, marginBottom: 10 }}>
        {[
          { label: "Baba", emoji: "🐦", color: colors.budgieBlue, genotype: "Gg" },
          { label: "Anne", emoji: "🐦", color: "#E91E63", genotype: "Gg" },
        ].map((parent, i) => {
          const p = Math.min(1, Math.max(0, (frame - 4 - i * 5) / 8));
          return (
            <div key={i} style={{
              flex: 1, display: "flex", alignItems: "center", gap: 5,
              backgroundColor: colors.surface, borderRadius: 10, padding: "7px 9px",
              border: `1px solid ${parent.color}30`,
              opacity: p, transform: `translateY(${(1 - p) * 8}px)`,
            }}>
              <span style={{ fontSize: 16 }}>{parent.emoji}</span>
              <div>
                <div style={{ fontSize: 10, fontWeight: 700, color: colors.textPrimary }}>{parent.label}</div>
                <div style={{ fontSize: 7.5, color: parent.color, fontWeight: 600 }}>{parent.genotype} (Taşıyıcı)</div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Animated arrow between parents and punnett */}
      <div style={{ textAlign: "center", marginBottom: 6 }}>
        <div style={{
          display: "inline-block", fontSize: 14, color: colors.textSecondary,
          opacity: interpolate(frame, [12, 18], [0, 0.5], { extrapolateRight: "clamp" }),
          transform: `translateY(${interpolate(frame, [12, 18], [5, 0], { extrapolateRight: "clamp" })}px)`,
        }}>▼</div>
      </div>

      <div style={{ backgroundColor: colors.surface, borderRadius: 11, padding: 10, border: `1px solid ${colors.surfaceVariant}` }}>
        <div style={{ fontSize: 10, fontWeight: 700, color: colors.textPrimary, marginBottom: 6 }}>Punnett Karesi</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 3 }}>
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
                padding: "7px 0", textAlign: "center",
                fontSize: isHeader ? 10 : 11, fontWeight: isHeader ? 700 : 600,
                color: isHeader ? colors.budgieTeal : colors.textPrimary,
                backgroundColor: bgColor, borderRadius: 5,
              }}>{cell}</div>
            );
          })}
        </div>
        <div style={{
          marginTop: 7, padding: "5px 8px",
          background: `linear-gradient(90deg, ${colors.primary}12, ${colors.accent}12)`,
          borderRadius: 5, display: "flex", justifyContent: "center", gap: 8,
          opacity: interpolate(frame, [35, 42], [0, 1], { extrapolateRight: "clamp" }),
        }}>
          {[
            { label: "GG", pct: 25, color: colors.primary },
            { label: "Gg", pct: 50, color: colors.budgieYellow },
            { label: "gg", pct: 25, color: colors.accent },
          ].map((r, i) => (
            <span key={i} style={{ fontSize: 8.5, fontWeight: 700, color: r.color }}>
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
export const PhoneDemoScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const phoneEntrance = spring({ frame, fps, config: springPresets.smooth });
  const phoneY = interpolate(phoneEntrance, [0, 1], [100, 0]);

  // Screen switching
  const dur = 70;
  const screenIndex = frame < dur ? 0 : frame < dur * 2 ? 1 : 2;
  const screenFrame = frame < dur ? frame : frame < dur * 2 ? frame - dur : frame - dur * 2;

  // 3D perspective
  const tiltX = interpolate(frame, [0, 50, 70], [30, 5, 0], { extrapolateRight: "clamp" });
  const tiltY = interpolate(frame, [0, 50, 70], [-20, -3, 0], { extrapolateRight: "clamp" });

  // Continuous subtle float
  const floatY = frame > 70 ? Math.sin((frame - 70) * 0.03) * 4 : 0;
  const floatRotate = frame > 70 ? Math.sin((frame - 70) * 0.02) * 1 : 0;

  const screenLabels = ["Kuş Yönetimi", "İstatistikler", "Genetik Hesaplama"];
  const titleOpacity = interpolate(frame, [0, 12], [0, 1], { extrapolateRight: "clamp" });

  // Screen transition (slide)
  const getOffset = (target: number) => {
    if (screenIndex === target) {
      const transFrame = target * dur;
      if (frame - transFrame < 8 && target > 0) {
        return interpolate(frame - transFrame, [0, 8], [300, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
      }
      return 0;
    }
    return screenIndex > target ? -300 : 300;
  };

  return (
    <AbsoluteFill style={{
      background: `radial-gradient(ellipse at 50% 35%, ${colors.gradient.mid}30 0%, ${colors.background} 65%)`,
      justifyContent: "center", alignItems: "center", overflow: "hidden",
    }}>
      {/* Animated grid */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px)`,
        backgroundSize: "80px 80px",
        transform: `translateY(${frame * 0.15}px)`,
      }} />

      {/* Ambient orbs */}
      {[0, 1, 2].map((i) => (
        <div key={i} style={{
          position: "absolute",
          width: 400 + i * 100, height: 400 + i * 100, borderRadius: "50%",
          background: `radial-gradient(circle, ${[colors.primary, colors.accent, colors.budgieYellow][i]}08 0%, transparent 60%)`,
          transform: `translate(${Math.sin(frame * 0.01 + i * 2) * 100}px, ${Math.cos(frame * 0.012 + i) * 60}px)`,
          filter: "blur(40px)",
        }} />
      ))}

      {/* Title */}
      <div style={{
        position: "absolute", top: 65, opacity: titleOpacity, textAlign: "center",
        fontFamily: fonts.title,
      }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 8,
          fontSize: 14, fontWeight: 700, color: colors.accent,
          letterSpacing: 4, textTransform: "uppercase", marginBottom: 10,
        }}>
          <div style={{ width: 30, height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
          Uygulama Önizleme
          <div style={{ width: 30, height: 1, backgroundColor: colors.accent, opacity: 0.4 }} />
        </div>
        <h2 style={{ fontSize: 48, fontWeight: 900, color: colors.textOnDark, margin: 0, textShadow: `0 0 25px ${colors.primary}25` }}>
          {screenLabels[screenIndex]}
        </h2>
      </div>

      {/* Phone */}
      <div style={{
        transform: `scale(${phoneEntrance * 0.92}) translateY(${phoneY + floatY}px) perspective(1200px) rotateX(${tiltX}deg) rotateY(${tiltY + floatRotate}deg)`,
        marginTop: 55,
      }}>
        {/* Shadow */}
        <div style={{
          position: "absolute", bottom: -45, left: 25, right: 25, height: 90,
          background: "radial-gradient(ellipse, rgba(0,0,0,0.5) 0%, transparent 70%)", filter: "blur(25px)",
        }} />

        {/* Phone body */}
        <div style={{
          width: 290, height: 600, backgroundColor: "#111", borderRadius: 38, padding: 7,
          boxShadow: `0 25px 70px rgba(0,0,0,0.6), inset 0 1px 2px rgba(255,255,255,0.25), 0 0 0 2.5px #333, 0 0 60px ${colors.primary}08`,
          position: "relative",
        }}>
          {/* Glass reflection */}
          <div style={{
            position: "absolute", inset: 0, borderRadius: 38,
            background: "linear-gradient(120deg, rgba(255,255,255,0.1) 0%, transparent 45%)",
            pointerEvents: "none", zIndex: 50,
          }} />

          {/* Dynamic Island */}
          <div style={{
            position: "absolute", top: 7, left: "50%", transform: "translateX(-50%)",
            width: 95, height: 26, backgroundColor: "#000", borderRadius: 18,
            zIndex: 10, display: "flex", justifyContent: "center", alignItems: "center",
          }}>
            <div style={{ width: 6, height: 6, borderRadius: "50%", backgroundColor: "#1a1a1a", border: "1px solid #222" }} />
          </div>

          {/* Screen */}
          <div style={{
            width: "100%", height: "100%", borderRadius: 31, overflow: "hidden",
            position: "relative", backgroundColor: colors.background,
          }}>
            {[0, 1, 2].map((idx) => {
              const offset = getOffset(idx);
              if (Math.abs(offset) >= 300 && screenIndex !== idx) return null;
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

          {/* Home indicator */}
          <div style={{
            position: "absolute", bottom: 8, left: "50%", transform: "translateX(-50%)",
            width: 105, height: 4, backgroundColor: "rgba(255,255,255,0.35)", borderRadius: 2, zIndex: 50,
          }} />
        </div>
      </div>

      {/* Screen dots */}
      <div style={{ position: "absolute", bottom: 48, display: "flex", gap: 8, alignItems: "center" }}>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{
            width: screenIndex === i ? 26 : 8, height: 8, borderRadius: 4,
            backgroundColor: screenIndex === i ? colors.primary : `${colors.textSecondary}35`,
            boxShadow: screenIndex === i ? `0 0 10px ${colors.primary}60` : "none",
          }} />
        ))}
      </div>
    </AbsoluteFill>
  );
};
