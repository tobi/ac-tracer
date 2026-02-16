// Bit operations library matching CSP/LuaJIT's bit.* API

export const bit = {
  band: (a: number, b: number): number => a & b,
  bor: (a: number, b: number): number => a | b,
  bxor: (a: number, b: number): number => a ^ b,
  bnot: (a: number): number => ~a,
  lshift: (a: number, n: number): number => a << n,
  rshift: (a: number, n: number): number => a >>> n, // Logical right shift
  arshift: (a: number, n: number): number => a >> n, // Arithmetic right shift
  rol: (a: number, n: number): number => (a << n) | (a >>> (32 - n)),
  ror: (a: number, n: number): number => (a >>> n) | (a << (32 - n)),
  tobit: (a: number): number => a | 0,
  tohex: (a: number, n?: number): string => {
    const hex = (a >>> 0).toString(16);
    const len = n !== undefined ? Math.abs(n) : 8;
    return hex.padStart(len, "0").slice(-len);
  },
};

export default bit;
