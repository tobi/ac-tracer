// Vector and color types matching CSP's API

export interface Vec2 {
  x: number;
  y: number;
}

export interface Vec3 {
  x: number;
  y: number;
  z: number;
}

export interface Vec4 {
  x: number;
  y: number;
  z: number;
  w: number;
}

export interface RGB {
  r: number;
  g: number;
  b: number;
}

export interface RGBM {
  r: number;
  g: number;
  b: number;
  mult: number;
}

// Constructors matching CSP API
export function vec2(x: number = 0, y: number = 0): Vec2 {
  return { x, y };
}

export function vec3(x: number = 0, y: number = 0, z: number = 0): Vec3 {
  return { x, y, z };
}

export function vec4(x: number = 0, y: number = 0, z: number = 0, w: number = 0): Vec4 {
  return { x, y, z, w };
}

export function rgb(r: number = 0, g: number = 0, b: number = 0): RGB {
  return { r, g, b };
}

export function rgbm(r: number = 0, g: number = 0, b: number = 0, mult: number = 1): RGBM {
  return { r, g, b, mult };
}

// Named colors
export const rgbmColors = {
  white: rgbm(1, 1, 1, 1),
  black: rgbm(0, 0, 0, 1),
  red: rgbm(1, 0, 0, 1),
  green: rgbm(0, 1, 0, 1),
  blue: rgbm(0, 0, 1, 1),
  yellow: rgbm(1, 1, 0, 1),
  cyan: rgbm(0, 1, 1, 1),
  magenta: rgbm(1, 0, 1, 1),
  transparent: rgbm(0, 0, 0, 0),
};

// Utility to convert RGBM to CSS color string
export function rgbmToCSS(c: RGBM, alphaOverride?: number): string {
  const alpha = alphaOverride !== undefined ? alphaOverride : c.mult;
  return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${alpha})`;
}

// Utility to convert RGB to CSS color string
export function rgbToCSS(c: RGB, alpha: number = 1): string {
  return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${alpha})`;
}
