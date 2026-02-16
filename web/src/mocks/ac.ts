// AC namespace mock - game state and utilities
// For web mode, most functions return mocked/null data since there's no live game

import { Vec3 } from "./vec";

// In-memory storage stub (Proxy behavior is lost when crossing the JS→Lua bridge,
// so we use a plain object pre-populated with defaults instead)
function storageWithDefaults(
  defaults?: Record<string, unknown>,
  _prefix?: string
): Record<string, unknown> {
  return defaults ? { ...defaults } : {};
}

// Mock car object (null in web mode - no live data)
const mockCar = null;

// Mock sim state
const mockSim = {
  trackLengthM: 5000,
  dt: 1 / 60,
  isPaused: false,
  isReplayActive: false,
  time: 0,
  gameTime: 0,
  currentSessionIndex: 0,
};

// Mock ControlButton for hotkey bindings (plain object so methods survive JS→Lua bridge)
function createMockControlButton() {
  return {
    pressed: () => false,
    down: () => false,
    control: (_size?: unknown) => {},
  };
}

// Track length cache (can be set when loading CSV)
let trackLengthM = 5000;

export function setTrackLength(meters: number) {
  trackLengthM = meters;
  mockSim.trackLengthM = meters;
}

export const ac = {
  // Car state (null in web mode)
  getCar: (_index: number) => mockCar,

  // Sim state
  getSim: () => ({ ...mockSim, trackLengthM }),

  // Track/car IDs
  getTrackID: () => "web_viewer",
  getCarID: (_index?: number) => "csv_import",
  getCarName: (_index?: number, _withYear?: boolean) => "CSV Import",
  getTrackSectorName: (_position: number) => "",

  // Storage
  storage: storageWithDefaults,

  // Logging
  log: (msg: string) => console.log("[AC]", msg),
  warn: (msg: string) => console.warn("[AC]", msg),
  error: (msg: string) => console.error("[AC]", msg),

  // Messages/notifications
  setMessage: (title: string, message: string) => {
    console.log(`[AC Message] ${title}: ${message}`);
  },

  // Clipboard
  setClipboardText: (text: string) => {
    navigator.clipboard.writeText(text).catch(console.error);
  },

  // Memory-mapped file (DLL) - not available in web
  readMemoryMappedFile: () => null,

  // Control button factory
  ControlButton: (_name: string, _defaults?: unknown) => createMockControlButton(),

  // Checkpoint/teleport APIs (not available in web)
  isCarResetAllowed: () => false,
  saveCarStateAsync: (_callback: Function) => {
    // No-op
  },
  loadCarState: () => {
    // No-op
  },
  onCarJumped: (_index: number, _callback: Function) => {
    // No-op
  },

  // Coordinate conversion (stub)
  trackCoordinateToWorld: (pos: Vec3) => pos,

  // App window access (not available in web)
  accessAppWindow: (_appName: string) => null,

  // Audio (stub)
  AudioEvent: {
    fromFile: (_opts: unknown) => ({
      isValid: () => false,
      start: () => {},
      stop: () => {},
      dispose: () => {},
      volume: 1.0,
      pitch: 1.0,
    }),
  },
};

export default ac;
