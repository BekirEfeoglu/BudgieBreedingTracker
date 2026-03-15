export const colors = {
  primary: "#14F195",
  primaryDark: "#0B9B5F",
  primaryLight: "#CBFCE5",
  accent: "#9945FF",
  accentDark: "#5B2A99",
  accentLight: "#E6D4FF",
  background: "#0a0a0a",
  backgroundDark: "#050505",
  surface: "#1A1A1D",
  surfaceVariant: "#252529",
  textPrimary: "#FDFDFD",
  textSecondary: "#AFAFAF",
  textOnPrimary: "#000000",
  textOnDark: "#FFFFFF",
  budgieYellow: "#FFD54F",
  budgieGreen: "#66BB6A",
  budgieBlue: "#42A5F5",
  budgieTeal: "#26A69A",
  eggCream: "#FFF8E1",
  heartRed: "#E53935",
  purple: "#AB47BC",
  gradient: {
    start: "#0a1f11",
    mid: "#113821",
    end: "#165830",
  },
  gradientWarm: {
    start: "#2A0E4F",
    mid: "#501B94",
    end: "#7424DB",
  },
};

export const fonts = {
  title: "'Outfit', 'Inter', 'SF Pro Display', sans-serif",
  body: "'Inter', 'SF Pro Text', sans-serif",
  mono: "'Fira Code', 'Menlo', monospace",
};

// Timing constants (in frames at 30fps)
export const timing = {
  fps: 30,
  totalDuration: 900, // 30 seconds

  intro:       { from: 0,   duration: 180 },
  features:    { from: 160, duration: 220 },
  phoneDemo:   { from: 360, duration: 220 },
  stats:       { from: 560, duration: 150 },
  techStack:   { from: 690, duration: 110 },
  outro:       { from: 780, duration: 120 },
};

// Spring presets
export const springPresets = {
  bouncy:    { damping: 10, mass: 0.8, stiffness: 120 },
  smooth:    { damping: 14, mass: 0.9, stiffness: 80 },
  snappy:    { damping: 12, mass: 0.5, stiffness: 150 },
  gentle:    { damping: 20, mass: 1.0, stiffness: 60 },
  elastic:   { damping: 8,  mass: 0.6, stiffness: 200 },
  heavy:     { damping: 18, mass: 1.2, stiffness: 90 },
  pop:       { damping: 6,  mass: 0.4, stiffness: 250 },
};

// Deterministic pseudo-random (seeded by index)
export const seededRandom = (seed: number) => {
  const x = Math.sin(seed * 127.1 + 311.7) * 43758.5453;
  return x - Math.floor(x);
};
