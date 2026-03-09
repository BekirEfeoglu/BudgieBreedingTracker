export const colors = {
  primary: "#4CAF50",
  primaryDark: "#388E3C",
  primaryLight: "#C8E6C9",
  accent: "#FF9800",
  accentDark: "#F57C00",
  accentLight: "#FFE0B2",
  background: "#FAFAFA",
  backgroundDark: "#1B5E20",
  surface: "#FFFFFF",
  surfaceVariant: "#F5F5F5",
  textPrimary: "#212121",
  textSecondary: "#757575",
  textOnPrimary: "#FFFFFF",
  textOnDark: "#FFFFFF",
  budgieYellow: "#FFD54F",
  budgieGreen: "#66BB6A",
  budgieBlue: "#42A5F5",
  budgieTeal: "#26A69A",
  eggCream: "#FFF8E1",
  heartRed: "#E53935",
  purple: "#AB47BC",
  gradient: {
    start: "#1B5E20",
    mid: "#2E7D32",
    end: "#4CAF50",
  },
  gradientWarm: {
    start: "#E65100",
    mid: "#FF9800",
    end: "#FFD54F",
  },
};

export const fonts = {
  title: "'Segoe UI', 'SF Pro Display', Arial, Helvetica, sans-serif",
  body: "'Segoe UI', 'SF Pro Text', Arial, Helvetica, sans-serif",
  mono: "'Fira Code', 'Cascadia Code', 'Consolas', monospace",
};

// Timing constants (in frames at 30fps)
export const timing = {
  fps: 30,
  totalDuration: 600, // 20 seconds

  intro:       { from: 0,   duration: 150 },  // 5 sec
  features:    { from: 130, duration: 150 },   // 5 sec
  phoneDemo:   { from: 260, duration: 120 },   // 4 sec
  stats:       { from: 360, duration: 100 },   // 3.3 sec
  techStack:   { from: 440, duration: 80 },    // 2.7 sec
  outro:       { from: 500, duration: 100 },   // 3.3 sec
};

// Easing presets
export const springPresets = {
  bouncy: { damping: 8, mass: 0.6, stiffness: 100 },
  smooth: { damping: 15, mass: 0.8 },
  snappy: { damping: 12, mass: 0.4 },
  gentle: { damping: 20, mass: 1.0 },
};
