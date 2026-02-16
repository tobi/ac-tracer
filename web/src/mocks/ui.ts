// UI namespace mock - renders CSP's ui.* API to Canvas 2D
import { Vec2, RGBM, vec2, rgbmToCSS } from "./vec";

// Font enum matching CSP
export const Font = {
  Small: "12px monospace",
  Main: "14px monospace",
  Title: "18px sans-serif",
  Monospace: "14px monospace",
};

// Style color enum (used with pushStyleColor)
export const StyleColor = {
  Text: 0,
  Button: 1,
  ButtonHovered: 2,
  ButtonActive: 3,
  FrameBg: 4,
  FrameBgHovered: 5,
  FrameBgActive: 6,
  WindowBg: 7,
  Border: 8,
};

// Style var enum (used with pushStyleVar)
export const StyleVar = {
  FramePadding: 0,
  ItemSpacing: 1,
  WindowPadding: 2,
  FrameRounding: 3,
};

// Mouse button enum
export const MouseButton = {
  Left: 0,
  Right: 1,
  Middle: 2,
};

// Input text flags
export const InputTextFlags = {
  None: 0,
  ReadOnly: 1,
  Password: 2,
};

// DWriteFont factory for custom fonts
export function DWriteFont(name: string) {
  let fontSize = 14;
  let fontWeight = 400;

  const font = {
    size: (s: number) => {
      fontSize = s;
      return font;
    },
    weight: (w: number) => {
      fontWeight = w;
      return font;
    },
    build: () => {
      const weightStr =
        fontWeight >= 700 ? "bold" : fontWeight >= 500 ? "500" : "normal";
      return `${weightStr} ${fontSize}px "${name}", monospace`;
    },
  };
  return font;
}

// UI context class that manages Canvas 2D rendering
class UIContext {
  canvas: HTMLCanvasElement | null = null;
  ctx: CanvasRenderingContext2D | null = null;

  // Layout state
  cursor: Vec2 = { x: 0, y: 0 };
  windowPos: Vec2 = { x: 0, y: 0 };
  windowSize: Vec2 = { x: 800, y: 600 };

  // Input state
  _mousePos: Vec2 = { x: 0, y: 0 };
  _mouseDown: boolean[] = [false, false, false];
  _mouseClicked: boolean[] = [false, false, false];
  _mouseReleased: boolean[] = [false, false, false];
  _wheelDelta: number = 0;
  _wheelDeltaH: number = 0;
  _drawCalls: number = 0;
  _lastItemHovered: boolean = false;
  _lastHoveredRect: { p1: Vec2; p2: Vec2 } | null = null;
  _tooltipText: string | null = null;

  // Style stacks
  fontStack: string[] = [Font.Main];
  colorStack: { type: number; color: RGBM }[] = [];
  styleVarStack: { var: number; value: number | Vec2 }[] = [];
  itemWidthStack: number[] = [];

  // Path for path-based drawing
  path: Vec2[] = [];

  // Child window state
  childClipRect: { x: number; y: number; w: number; h: number } | null = null;

  setCanvas(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.windowSize = { x: canvas.width, y: canvas.height };
  }

  beginFrameForCanvasRender() {
    this._tooltipText = null;
    this._lastItemHovered = false;
    this._lastHoveredRect = null;
  }

  // Reset per-frame state
  beginFrame() {
    // Clear click states (they're single-frame)
    this._mouseClicked = [false, false, false];
    this._mouseReleased = [false, false, false];
    this._wheelDelta = 0;
    this._wheelDeltaH = 0;
    this.cursor = { x: 0, y: 0 };
    this._lastItemHovered = false;
    this._lastHoveredRect = null;
    this._tooltipText = null;
  }

  // Event handlers
  handleMouseMove(e: MouseEvent) {
    if (!this.canvas) return;
    const rect = this.canvas.getBoundingClientRect();
    // Use CSS pixel coordinates (not physical pixels) to match Lua's coordinate space
    this._mousePos = {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top,
    };
  }

  handleMouseDown(e: MouseEvent) {
    const btn = e.button;
    if (btn >= 0 && btn < 3) {
      this._mouseDown[btn] = true;
      this._mouseClicked[btn] = true;
    }
  }

  handleMouseUp(e: MouseEvent) {
    const btn = e.button;
    if (btn >= 0 && btn < 3) {
      this._mouseDown[btn] = false;
      this._mouseReleased[btn] = true;
    }
  }

  handleWheel(e: WheelEvent) {
    this._wheelDelta = -e.deltaY / 100;
    this._wheelDeltaH = -e.deltaX / 100;
  }

  // Current font/color helpers
  currentFont(): string {
    return this.fontStack[this.fontStack.length - 1] || Font.Main;
  }

  currentColor(): RGBM {
    return this.resolveColor(StyleColor.Text) || { r: 1, g: 1, b: 1, mult: 1 };
  }

  private resolveColor(type: number): RGBM | undefined {
    for (let i = this.colorStack.length - 1; i >= 0; i--) {
      const entry = this.colorStack[i];
      if (entry.type === type) return entry.color;
    }
    return undefined;
  }

  private buttonColor(hovered: boolean, clicked: boolean): RGBM {
    const normal = this.resolveColor(StyleColor.Button);
    const hoveredColor = this.resolveColor(StyleColor.ButtonHovered);
    const activeColor = this.resolveColor(StyleColor.ButtonActive);

    if (activeColor && (clicked || this._mouseDown[0])) return activeColor;
    if (clicked) return activeColor || (normal ? this.withDarken(normal, 0.15) : { r: 0.2, g: 0.4, b: 0.6, mult: 1 });
    if (hovered) return hoveredColor || (normal ? this.withLighten(normal, 0.12) : { r: 0.15, g: 0.35, b: 0.55, mult: 1 });
    return normal || { r: 0.1, g: 0.3, b: 0.5, mult: 1 };
  }

  private buttonBorderColor(): RGBM {
    const base = this.buttonColor(false, false);
    return this.withDarken(base, 0.2);
  }

  private withLighten(color: RGBM, amount: number): RGBM {
    return {
      r: Math.min(1, color.r + amount),
      g: Math.min(1, color.g + amount),
      b: Math.min(1, color.b + amount),
      mult: color.mult,
    };
  }

  private withDarken(color: RGBM, amount: number): RGBM {
    return {
      r: Math.max(0, color.r - amount),
      g: Math.max(0, color.g - amount),
      b: Math.max(0, color.b - amount),
      mult: color.mult,
    };
  }

  // =========================================================================
  // Layout Functions
  // =========================================================================

  setCursor(pos: Vec2) {
    this.cursor = { x: pos.x, y: pos.y };
  }

  getCursor(): Vec2 {
    return { ...this.cursor };
  }

  getCursorX(): number {
    return this.cursor.x;
  }

  getCursorY(): number {
    return this.cursor.y;
  }

  offsetCursor(offset: Vec2) {
    this.cursor.x += offset.x;
    this.cursor.y += offset.y;
  }

  offsetCursorX(x: number) {
    this.cursor.x += x;
  }

  offsetCursorY(y: number) {
    this.cursor.y += y;
  }

  sameLine(xPos?: number) {
    // Move cursor back to same Y but different X
    this.cursor.y -= 16; // Undo last line advance
    if (xPos !== undefined) {
      this.cursor.x = xPos;
    }
  }

  availableSpace(): Vec2 {
    return {
      x: this.windowSize.x - this.cursor.x,
      y: this.windowSize.y - this.cursor.y,
    };
  }

  availableSpaceX(): number {
    return this.windowSize.x - this.cursor.x;
  }

  availableSpaceY(): number {
    return this.windowSize.y - this.cursor.y;
  }

  getWindowPos(): Vec2 {
    return { ...this.windowPos };
  }

  windowWidth(): number {
    return this.windowSize.x;
  }

  windowHeight(): number {
    return this.windowSize.y;
  }

  // =========================================================================
  // Style Functions
  // =========================================================================

  pushFont(font: string | { build?: () => string }) {
    if (typeof font === "object" && font.build) {
      this.fontStack.push(font.build());
    } else if (typeof font === "string") {
      this.fontStack.push(font);
    }
  }

  popFont(count: number = 1) {
    for (let i = 0; i < count && this.fontStack.length > 1; i++) {
      this.fontStack.pop();
    }
  }

  pushStyleColor(_styleType: number, color: RGBM) {
    this.colorStack.push({ type: _styleType, color });
  }

  popStyleColor(count: number = 1) {
    for (let i = 0; i < count && this.colorStack.length > 0; i++) {
      this.colorStack.pop();
    }
  }

  pushStyleVar(_varType: number, value: number | Vec2) {
    this.styleVarStack.push({ var: _varType, value });
  }

  popStyleVar(count: number = 1) {
    for (let i = 0; i < count && this.styleVarStack.length > 0; i++) {
      this.styleVarStack.pop();
    }
  }

  setNextItemWidth(width: number) {
    this.itemWidthStack.push(width);
  }

  pushItemWidth(width: number) {
    this.itemWidthStack.push(width);
  }

  popItemWidth() {
    this.itemWidthStack.pop();
  }

  // =========================================================================
  // Drawing Functions
  // =========================================================================

  drawLine(p1: Vec2, p2: Vec2, color: RGBM, thickness: number = 1) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.strokeStyle = rgbmToCSS(color);
    this.ctx.lineWidth = thickness;
    this.ctx.beginPath();
    this.ctx.moveTo(p1.x, p1.y);
    this.ctx.lineTo(p2.x, p2.y);
    this.ctx.stroke();
  }

  drawRect(
    p1: Vec2,
    p2: Vec2,
    color: RGBM,
    radius: number = 0,
    thickness: number = 1
  ) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.strokeStyle = rgbmToCSS(color);
    this.ctx.lineWidth = thickness;

    const x = Math.min(p1.x, p2.x);
    const y = Math.min(p1.y, p2.y);
    const w = Math.abs(p2.x - p1.x);
    const h = Math.abs(p2.y - p1.y);

    if (radius > 0) {
      this.ctx.beginPath();
      this.ctx.roundRect(x, y, w, h, radius);
      this.ctx.stroke();
    } else {
      this.ctx.strokeRect(x, y, w, h);
    }
  }

  drawRectFilled(p1: Vec2, p2: Vec2, color: RGBM, radius: number = 0) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.fillStyle = rgbmToCSS(color);

    const x = Math.min(p1.x, p2.x);
    const y = Math.min(p1.y, p2.y);
    const w = Math.abs(p2.x - p1.x);
    const h = Math.abs(p2.y - p1.y);

    if (radius > 0) {
      this.ctx.beginPath();
      this.ctx.roundRect(x, y, w, h, radius);
      this.ctx.fill();
    } else {
      this.ctx.fillRect(x, y, w, h);
    }
  }

  drawCircle(
    center: Vec2,
    radius: number,
    color: RGBM,
    segments: number = 32,
    thickness: number = 1
  ) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.strokeStyle = rgbmToCSS(color);
    this.ctx.lineWidth = thickness;
    this.ctx.beginPath();
    this.ctx.arc(center.x, center.y, radius, 0, Math.PI * 2);
    this.ctx.stroke();
  }

  drawCircleFilled(
    center: Vec2,
    radius: number,
    color: RGBM,
    segments: number = 32
  ) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.fillStyle = rgbmToCSS(color);
    this.ctx.beginPath();
    this.ctx.arc(center.x, center.y, radius, 0, Math.PI * 2);
    this.ctx.fill();
  }

  drawTriangleFilled(p1: Vec2, p2: Vec2, p3: Vec2, color: RGBM) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.fillStyle = rgbmToCSS(color);
    this.ctx.beginPath();
    this.ctx.moveTo(p1.x, p1.y);
    this.ctx.lineTo(p2.x, p2.y);
    this.ctx.lineTo(p3.x, p3.y);
    this.ctx.closePath();
    this.ctx.fill();
  }

  drawQuadFilled(p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, color: RGBM) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.fillStyle = rgbmToCSS(color);
    this.ctx.beginPath();
    this.ctx.moveTo(p1.x, p1.y);
    this.ctx.lineTo(p2.x, p2.y);
    this.ctx.lineTo(p3.x, p3.y);
    this.ctx.lineTo(p4.x, p4.y);
    this.ctx.closePath();
    this.ctx.fill();
  }

  // =========================================================================
  // Path Drawing
  // =========================================================================

  pathClear() {
    this.path = [];
  }

  pathLineTo(p: Vec2) {
    this._drawCalls++;
    this.path.push({ x: p.x, y: p.y });
  }

  pathArcTo(center: Vec2, radius: number, angleMin: number, angleMax: number, segments: number = 16) {
    for (let i = 0; i <= segments; i++) {
      const angle = angleMin + (angleMax - angleMin) * (i / segments);
      this.path.push({
        x: center.x + Math.cos(angle) * radius,
        y: center.y + Math.sin(angle) * radius,
      });
    }
  }

  pathStroke(color: RGBM, closed: boolean = false, thickness: number = 1) {
    this._drawCalls++;
    if (!this.ctx || this.path.length < 2) return;

    this.ctx.strokeStyle = rgbmToCSS(color);
    this.ctx.lineWidth = thickness;
    this.ctx.beginPath();
    this.ctx.moveTo(this.path[0].x, this.path[0].y);

    for (let i = 1; i < this.path.length; i++) {
      this.ctx.lineTo(this.path[i].x, this.path[i].y);
    }

    if (closed) this.ctx.closePath();
    this.ctx.stroke();
    this.path = []; // CSP auto-clears path after stroke
  }

  pathFillConvex(color: RGBM) {
    this._drawCalls++;
    if (!this.ctx || this.path.length < 3) return;

    this.ctx.fillStyle = rgbmToCSS(color);
    this.ctx.beginPath();
    this.ctx.moveTo(this.path[0].x, this.path[0].y);

    for (let i = 1; i < this.path.length; i++) {
      this.ctx.lineTo(this.path[i].x, this.path[i].y);
    }

    this.ctx.closePath();
    this.ctx.fill();
    this.path = []; // CSP auto-clears path after fill
  }

  // =========================================================================
  // Text Functions
  // =========================================================================

  text(str: string) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.fillStyle = rgbmToCSS(this.currentColor());
    this.ctx.font = this.currentFont();
    this.ctx.textBaseline = "top";
    this.ctx.fillText(str, this.cursor.x, this.cursor.y);
    this.cursor.y += 16; // Line height
  }

  textColored(str: string, color: RGBM) {
    if (!this.ctx) return;
    this.ctx.fillStyle = rgbmToCSS(color);
    this.ctx.font = this.currentFont();
    this.ctx.textBaseline = "top";
    this.ctx.fillText(str, this.cursor.x, this.cursor.y);
    this.cursor.y += 16;
  }

  textAligned(str: string, align: Vec2, size: Vec2) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.fillStyle = rgbmToCSS(this.currentColor());
    this.ctx.font = this.currentFont();

    // Set alignment
    this.ctx.textAlign = align.x < 0.3 ? "left" : align.x > 0.7 ? "right" : "center";
    this.ctx.textBaseline = align.y < 0.3 ? "top" : align.y > 0.7 ? "bottom" : "middle";

    const x = this.cursor.x + size.x * align.x;
    const y = this.cursor.y + size.y * align.y;
    this.ctx.fillText(str, x, y);

    // Reset
    this.ctx.textAlign = "left";
    this.ctx.textBaseline = "top";
  }

  measureText(str: string): Vec2 {
    if (!this.ctx) return { x: 0, y: 14 };
    this.ctx.font = this.currentFont();
    const metrics = this.ctx.measureText(str);
    return { x: metrics.width, y: 14 };
  }

  // DirectWrite text rendering with clipping
  dwriteDrawText(
    text: string,
    fontSize: number,
    pos: Vec2,
    color: RGBM
  ) {
    this._drawCalls++;
    if (!this.ctx) return;
    this.ctx.fillStyle = rgbmToCSS(color);
    this.ctx.font = `${fontSize}px monospace`;
    this.ctx.textBaseline = "top";
    this.ctx.fillText(text, pos.x, pos.y);
  }

  dwriteDrawTextClipped(
    text: string,
    fontSize: number,
    p1: Vec2,
    p2: Vec2,
    alignX: number,
    alignY: number,
    wrap: boolean,
    color: RGBM
  ) {
    if (!this.ctx) return;

    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.rect(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
    this.ctx.clip();

    this.ctx.font = `${fontSize}px monospace`;
    this.ctx.fillStyle = rgbmToCSS(color);
    this.ctx.textAlign = alignX < 0.3 ? "left" : alignX > 0.7 ? "right" : "center";
    this.ctx.textBaseline = alignY < 0.3 ? "top" : alignY > 0.7 ? "bottom" : "middle";

    const x = p1.x + (p2.x - p1.x) * alignX;
    const y = p1.y + (p2.y - p1.y) * alignY;
    this.ctx.fillText(text, x, y);

    this.ctx.restore();
  }

  // =========================================================================
  // Input Functions
  // =========================================================================

  mousePos(): Vec2 {
    return { ...this._mousePos };
  }

  mouseClicked(button: number = 0): boolean {
    return this._mouseClicked[button] || false;
  }

  mouseDoubleClicked(button: number = 0): boolean {
    // Not implemented - would need timing logic
    return false;
  }

  mouseDown(button: number = 0): boolean {
    return this._mouseDown[button] || false;
  }

  mouseReleased(button: number = 0): boolean {
    return this._mouseReleased[button] || false;
  }

  mouseWheel(): number {
    return this._wheelDelta;
  }

  mouseWheelH(): number {
    return this._wheelDeltaH;
  }

  rectHovered(p1: Vec2, p2: Vec2): boolean {
    const m = this._mousePos;
    const minX = Math.min(p1.x, p2.x);
    const maxX = Math.max(p1.x, p2.x);
    const minY = Math.min(p1.y, p2.y);
    const maxY = Math.max(p1.y, p2.y);
    return m.x >= minX && m.x <= maxX && m.y >= minY && m.y <= maxY;
  }

  itemHovered(): boolean {
    return this._lastItemHovered;
  }

  // =========================================================================
  // UI Controls
  // =========================================================================

  button(label: string, size?: Vec2): boolean {
    if (!this.ctx) return false;

    const padding = 8;
    const textSize = this.measureText(label);
    const btnSize = size || { x: textSize.x + padding * 2, y: 24 };
    const p1 = { ...this.cursor };
    const p2 = { x: p1.x + btnSize.x, y: p1.y + btnSize.y };

    const hovered = this.rectHovered(p1, p2);
    const clicked = hovered && this._mouseClicked[0];
    this._lastItemHovered = hovered;
    this._lastHoveredRect = { p1: { ...p1 }, p2: { ...p2 } };

    const bgColor = this.buttonColor(hovered, clicked);
    const borderColor = this.buttonBorderColor();
    const textColor = this.resolveColor(StyleColor.Text) || { r: 1, g: 1, b: 1, mult: 1 };
    this.drawRectFilled(p1, p2, bgColor, 4);
    this.drawRect(p1, p2, borderColor, 4, hovered || clicked ? 2 : 1);

    // Draw label
    this.ctx.fillStyle = rgbmToCSS(textColor);
    this.ctx.font = this.currentFont();
    this.ctx.textAlign = "center";
    this.ctx.textBaseline = "middle";
    this.ctx.fillText(label, (p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    this.ctx.textAlign = "left";
    this.ctx.textBaseline = "top";

    this.cursor.y = p2.y + 4;
    return clicked;
  }

  invisibleButton(id: string, size: Vec2): boolean {
    const p1 = { ...this.cursor };
    const p2 = { x: p1.x + size.x, y: p1.y + size.y };
    const hovered = this.rectHovered(p1, p2);
    this._lastItemHovered = hovered;
    this._lastHoveredRect = { p1: { ...p1 }, p2: { ...p2 } };
    return hovered && this._mouseClicked[0];
  }

  checkbox(label: string, value: boolean): boolean {
    if (!this.ctx) return value;

    const size = 16;
    const p1 = { ...this.cursor };
    const p2 = { x: p1.x + size, y: p1.y + size };

    const hovered = this.rectHovered(p1, p2);
    const clicked = hovered && this._mouseClicked[0];
    this._lastItemHovered = hovered;
    this._lastHoveredRect = { p1: { ...p1 }, p2: { ...p2 } };

    // Draw checkbox
    this.drawRect(p1, p2, { r: 0.5, g: 0.5, b: 0.5, mult: 1 }, 2);
    if (value) {
      this.drawRectFilled(
        { x: p1.x + 3, y: p1.y + 3 },
        { x: p2.x - 3, y: p2.y - 3 },
        { r: 0.2, g: 0.6, b: 1, mult: 1 },
        2
      );
    }

    // Draw label
    this.ctx.fillStyle = "#fff";
    this.ctx.font = this.currentFont();
    this.ctx.textBaseline = "middle";
    this.ctx.fillText(label, p2.x + 8, (p1.y + p2.y) / 2);
    this.ctx.textBaseline = "top";

    this.cursor.y = p2.y + 4;

    return clicked ? !value : value;
  }

  slider(
    id: string,
    value: number,
    min: number,
    max: number,
    format?: string
  ): number {
    if (!this.ctx) return value;

    const width = this.itemWidthStack[this.itemWidthStack.length - 1] || 200;
    const height = 20;
    const p1 = { ...this.cursor };
    const p2 = { x: p1.x + width, y: p1.y + height };

    const hovered = this.rectHovered(p1, p2);
    const dragging = hovered && this._mouseDown[0];
    this._lastItemHovered = hovered;
    this._lastHoveredRect = { p1: { ...p1 }, p2: { ...p2 } };

    // Draw track
    this.drawRectFilled(p1, p2, { r: 0.2, g: 0.2, b: 0.25, mult: 1 }, 4);

    // Calculate thumb position
    const normalizedValue = (value - min) / (max - min);
    const thumbX = p1.x + normalizedValue * (width - 8);

    // Draw filled portion
    this.drawRectFilled(
      p1,
      { x: thumbX + 4, y: p2.y },
      { r: 0.2, g: 0.5, b: 0.8, mult: 1 },
      4
    );

    // Update value if dragging
    let newValue = value;
    if (dragging) {
      const relX = Math.max(0, Math.min(width, this._mousePos.x - p1.x));
      newValue = min + (relX / width) * (max - min);
    }

    this.cursor.y = p2.y + 4;
    return newValue;
  }

  inputText(id: string, text: string, flags: number = 0): string {
    // Simplified - just display the text in a box
    if (!this.ctx) return text;

    const width = this.itemWidthStack[this.itemWidthStack.length - 1] || 200;
    const height = 22;
    const p1 = { ...this.cursor };
    const p2 = { x: p1.x + width, y: p1.y + height };
    const hovered = this.rectHovered(p1, p2);
    this._lastItemHovered = hovered;
    this._lastHoveredRect = { p1: { ...p1 }, p2: { ...p2 } };

    this.drawRectFilled(p1, p2, { r: 0.15, g: 0.15, b: 0.2, mult: 1 }, 2);
    this.drawRect(p1, p2, { r: 0.3, g: 0.3, b: 0.35, mult: 1 }, 2);

    this.ctx.fillStyle = "#fff";
    this.ctx.font = this.currentFont();
    this.ctx.textBaseline = "middle";
    this.ctx.fillText(text, p1.x + 4, (p1.y + p2.y) / 2);
    this.ctx.textBaseline = "top";

    this.cursor.y = p2.y + 4;
    return text;
  }

  // =========================================================================
  // Child Windows
  // =========================================================================

  childWindow(id: string, size: Vec2, callback: () => void) {
    if (!this.ctx) return;

    const p1 = { ...this.cursor };
    const p2 = { x: p1.x + size.x, y: p1.y + size.y };

    // Save state
    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.rect(p1.x, p1.y, size.x, size.y);
    this.ctx.clip();

    const oldCursor = { ...this.cursor };
    callback();

    this.cursor = oldCursor;
    this.cursor.y = p2.y + 4;
    this.ctx.restore();
  }

  // =========================================================================
  // Tooltip
  // =========================================================================

  setTooltip(text: string) {
    this._tooltipText = text;
  }

  drawTooltip() {
    if (!this._tooltipText || !this._mousePos || !this.ctx) return;
    const text = this._tooltipText;
    const padding = 8;
    const previousFont = this.ctx.font;
    const previousAlign = this.ctx.textAlign;
    const previousBaseline = this.ctx.textBaseline;

    this.ctx.font = Font.Main;
    const metrics = this.ctx.measureText(text);
    const w = metrics.width + padding * 2;
    const h = 20;
    const x = this._mousePos.x + 14;
    const y = this._mousePos.y + 14;

    this.ctx.fillStyle = "rgba(10, 14, 22, 0.95)";
    this.ctx.strokeStyle = "rgba(90, 120, 170, 0.9)";
    this.ctx.lineWidth = 1;
    this.ctx.beginPath();
    this.ctx.roundRect(x, y, w, h, 4);
    this.ctx.fill();
    this.ctx.stroke();

    this.ctx.fillStyle = "#d8deec";
    this.ctx.textAlign = "left";
    this.ctx.textBaseline = "middle";
    this.ctx.fillText(text, x + padding, y + h / 2);

    this.ctx.font = previousFont;
    this.ctx.textAlign = previousAlign;
    this.ctx.textBaseline = previousBaseline;
  }
}

// Create singleton instance
export const uiContext = new UIContext();

// Export the ui namespace object for Lua
export const ui = {
  // Enums
  Font,
  StyleColor,
  StyleVar,
  MouseButton,
  InputTextFlags,
  DWriteFont,

  // Layout
  setCursor: (pos: Vec2) => uiContext.setCursor(pos),
  getCursor: () => uiContext.getCursor(),
  getCursorX: () => uiContext.getCursorX(),
  getCursorY: () => uiContext.getCursorY(),
  offsetCursor: (offset: Vec2) => uiContext.offsetCursor(offset),
  offsetCursorX: (x: number) => uiContext.offsetCursorX(x),
  offsetCursorY: (y: number) => uiContext.offsetCursorY(y),
  sameLine: (xPos?: number) => uiContext.sameLine(xPos),
  availableSpace: () => uiContext.availableSpace(),
  availableSpaceX: () => uiContext.availableSpaceX(),
  availableSpaceY: () => uiContext.availableSpaceY(),
  windowPos: () => uiContext.getWindowPos(),
  windowWidth: () => uiContext.windowWidth(),
  windowHeight: () => uiContext.windowHeight(),

  // Styling
  pushFont: (font: string | object) => uiContext.pushFont(font as any),
  popFont: (count?: number) => uiContext.popFont(count),
  pushStyleColor: (type: number, color: RGBM) =>
    uiContext.pushStyleColor(type, color),
  popStyleColor: (count?: number) => uiContext.popStyleColor(count),
  pushStyleVar: (type: number, value: number | Vec2) =>
    uiContext.pushStyleVar(type, value),
  popStyleVar: (count?: number) => uiContext.popStyleVar(count),
  setNextItemWidth: (width: number) => uiContext.setNextItemWidth(width),
  pushItemWidth: (width: number) => uiContext.pushItemWidth(width),
  popItemWidth: () => uiContext.popItemWidth(),

  // Drawing
  drawLine: (p1: Vec2, p2: Vec2, color: RGBM, thickness?: number) =>
    uiContext.drawLine(p1, p2, color, thickness),
  drawRect: (
    p1: Vec2,
    p2: Vec2,
    color: RGBM,
    radius?: number,
    thickness?: number
  ) => uiContext.drawRect(p1, p2, color, radius, thickness),
  drawRectFilled: (p1: Vec2, p2: Vec2, color: RGBM, radius?: number) =>
    uiContext.drawRectFilled(p1, p2, color, radius),
  drawCircle: (
    center: Vec2,
    radius: number,
    color: RGBM,
    segments?: number,
    thickness?: number
  ) => uiContext.drawCircle(center, radius, color, segments, thickness),
  drawCircleFilled: (
    center: Vec2,
    radius: number,
    color: RGBM,
    segments?: number
  ) => uiContext.drawCircleFilled(center, radius, color, segments),
  drawTriangleFilled: (p1: Vec2, p2: Vec2, p3: Vec2, color: RGBM) =>
    uiContext.drawTriangleFilled(p1, p2, p3, color),
  drawQuadFilled: (p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, color: RGBM) =>
    uiContext.drawQuadFilled(p1, p2, p3, p4, color),

  // Paths
  pathClear: () => uiContext.pathClear(),
  pathLineTo: (p: Vec2) => uiContext.pathLineTo(p),
  pathArcTo: (center: Vec2, radius: number, angleMin: number, angleMax: number, segments?: number) =>
    uiContext.pathArcTo(center, radius, angleMin, angleMax, segments),
  pathStroke: (color: RGBM, closed?: boolean, thickness?: number) =>
    uiContext.pathStroke(color, closed, thickness),
  pathFillConvex: (color: RGBM) => uiContext.pathFillConvex(color),

  // Text
  text: (str: string) => uiContext.text(str),
  textColored: (str: string, color: RGBM) => uiContext.textColored(str, color),
  textAligned: (str: string, align: Vec2, size: Vec2) =>
    uiContext.textAligned(str, align, size),
  measureText: (str: string) => uiContext.measureText(str),
  dwriteDrawText: (text: string, fontSize: number, pos: Vec2, color: RGBM) =>
    uiContext.dwriteDrawText(text, fontSize, pos, color),
  dwriteDrawTextClipped: (
    text: string,
    fontSize: number,
    p1: Vec2,
    p2: Vec2,
    alignX: number,
    alignY: number,
    wrap: boolean,
    color: RGBM
  ) => uiContext.dwriteDrawTextClipped(text, fontSize, p1, p2, alignX, alignY, wrap, color),

  // Input
  mousePos: () => uiContext.mousePos(),
  mouseClicked: (button?: number) => uiContext.mouseClicked(button),
  mouseDoubleClicked: (button?: number) => uiContext.mouseDoubleClicked(button),
  mouseDown: (button?: number) => uiContext.mouseDown(button),
  mouseReleased: (button?: number) => uiContext.mouseReleased(button),
  mouseWheel: () => uiContext.mouseWheel(),
  mouseWheelH: () => uiContext.mouseWheelH(),
  rectHovered: (p1: Vec2, p2: Vec2) => uiContext.rectHovered(p1, p2),
  itemHovered: () => uiContext.itemHovered(),

  // Controls
  button: (label: string, size?: Vec2) => uiContext.button(label, size),
  invisibleButton: (id: string, size: Vec2) =>
    uiContext.invisibleButton(id, size),
  checkbox: (label: string, value: boolean) => uiContext.checkbox(label, value),
  slider: (id: string, value: number, min: number, max: number, format?: string) =>
    uiContext.slider(id, value, min, max, format),
  inputText: (id: string, text: string, flags?: number) =>
    uiContext.inputText(id, text, flags),

  // Windows
  childWindow: (id: string, size: Vec2, callback: () => void) =>
    uiContext.childWindow(id, size, callback),

  // Misc
  setTooltip: (text: string) => uiContext.setTooltip(text),
  beginFrameForCanvasRender: () => uiContext.beginFrameForCanvasRender(),
  drawTooltip: () => uiContext.drawTooltip(),
};

export default ui;
