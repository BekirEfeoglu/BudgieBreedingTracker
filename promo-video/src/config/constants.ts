export const FPS = 30;
export const WIDTH = 1080;
export const HEIGHT = 1920;
export const TOTAL_FRAMES = 2400; // 80 seconds

// Scene start frames and durations
export const SCENES = {
  intro:      { start: 0,    duration: 180 },  // 6s
  dashboard:  { start: 180,  duration: 300 },  // 10s
  birds:      { start: 480,  duration: 300 },  // 10s
  breeding:   { start: 780,  duration: 420 },  // 14s
  genetics:   { start: 1200, duration: 360 },  // 12s
  stats:      { start: 1560, duration: 300 },  // 10s
  smart:      { start: 1860, duration: 240 },  // 8s
  premium:    { start: 2100, duration: 300 },  // 10s
} as const;

export const TRANSITION_FRAMES = 15; // 0.5s scene transition

// Spring animation presets
export const SPRINGS = {
  gentle: { damping: 15, mass: 1, stiffness: 80 },
  bouncy: { damping: 12, mass: 1, stiffness: 120 },
  snappy: { damping: 20, mass: 0.8, stiffness: 200 },
} as const;

// Phone mockup dimensions (iPhone 14 Pro ratio)
export const PHONE = {
  width: 340,
  height: 736,
  bezel: 8,
  borderRadius: 40,
  notchWidth: 140,
  notchHeight: 30,
  screenBorderRadius: 34,
} as const;

// Layout
export const LAYOUT = {
  phoneCenterX: WIDTH / 2,
  featureColumnX: WIDTH * 0.7,
  padding: 60,
  sectionGap: 24,
} as const;
