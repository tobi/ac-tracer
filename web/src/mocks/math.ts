// Extended math functions matching CSP's API

export const extendedMath = {
  ...Math,

  // Clamp value between min and max
  clamp: (v: number, min: number, max: number): number => {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  },

  // Sign function (-1, 0, or 1)
  sign: (v: number): number => {
    if (v > 0) return 1;
    if (v < 0) return -1;
    return 0;
  },

  // Linear interpolation
  lerp: (a: number, b: number, t: number): number => {
    return a + (b - a) * t;
  },

  // Saturate (clamp to 0-1)
  saturate: (v: number): number => {
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  },

  // Round to specified decimal places
  round: (v: number, decimals?: number): number => {
    if (decimals === undefined || decimals === 0) {
      return Math.round(v);
    }
    const mult = Math.pow(10, decimals);
    return Math.round(v * mult) / mult;
  },

  // Smooth step interpolation
  smoothstep: (edge0: number, edge1: number, x: number): number => {
    const t = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
    return t * t * (3 - 2 * t);
  },

  // Remap value from one range to another
  remap: (
    value: number,
    inMin: number,
    inMax: number,
    outMin: number,
    outMax: number
  ): number => {
    return outMin + ((value - inMin) / (inMax - inMin)) * (outMax - outMin);
  },

  // Angle difference (handles wrapping)
  angleDiff: (a: number, b: number): number => {
    let diff = ((b - a + Math.PI) % (2 * Math.PI)) - Math.PI;
    return diff < -Math.PI ? diff + 2 * Math.PI : diff;
  },

  // Check if approximately equal
  isApprox: (a: number, b: number, epsilon: number = 1e-6): boolean => {
    return Math.abs(a - b) < epsilon;
  },
};

export default extendedMath;
