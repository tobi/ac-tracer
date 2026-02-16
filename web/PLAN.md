# AC Tracer Web - Implementation Plan

## Goal
Run the existing Lua telemetry tools (lap_telemetry.lua, corner_analysis.lua) unchanged in a web browser, supporting CSV file loading and full UI rendering.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Web Browser                                │
├──────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    Bun/Vite Dev Server                      │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                     React App Shell                         │  │
│  │  - File drop zone                                           │  │
│  │  - Canvas container                                         │  │
│  │  - Controls (lap picker, settings)                          │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                 wasmoon (Lua 5.4 WASM)                      │  │
│  │  - Runs UNCHANGED Lua code from ../lib/                     │  │
│  │  - lap.lua, lap_csv_parser.lua, corner_analysis.lua         │  │
│  │  - theme.lua, scoring.lua, ui_utils.lua                     │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │               CSP API Mocks (TypeScript)                    │  │
│  │  - ac.* → Mock game state                                   │  │
│  │  - ui.* → Canvas 2D rendering                               │  │
│  │  - io.* → Virtual filesystem + drag-drop                    │  │
│  │  - ac.storage → localStorage                                │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                  HTML5 Canvas (2D)                          │  │
│  │  - Renders all ui.draw* calls                               │  │
│  │  - Mouse input → Lua cursor/click events                    │  │
│  │  - 60fps render loop                                        │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Component | Technology | Rationale |
|-----------|------------|-----------|
| Package Manager | Bun | Fast, native TS support |
| Build Tool | Vite | Fast HMR, ESM native |
| UI Framework | React 18 | Canvas management, file drop |
| Lua Runtime | wasmoon | Lua 5.4 via WASM, well-maintained |
| Rendering | Canvas 2D | Simple, sufficient for ImGui-style UI |
| Styling | Tailwind CSS | Quick layout for app shell |

---

## Phase 1: Project Setup

### 1.1 Initialize Bun + Vite + React

```bash
cd web/
bun create vite . --template react-ts
bun add wasmoon
bun add -D tailwindcss postcss autoprefixer
```

### 1.2 Project Structure

```
web/
├── src/
│   ├── main.tsx              # Entry point
│   ├── App.tsx               # Main app shell
│   ├── components/
│   │   ├── Canvas.tsx        # Canvas wrapper with render loop
│   │   ├── FileDrop.tsx      # Drag-drop CSV loader
│   │   └── Controls.tsx      # Lap picker, settings panel
│   ├── lua/
│   │   ├── engine.ts         # wasmoon setup, Lua execution
│   │   ├── loader.ts         # Load Lua files from ../lib/
│   │   └── vfs.ts            # Virtual filesystem for io.*
│   ├── mocks/
│   │   ├── ac.ts             # ac.* namespace mock
│   │   ├── ui.ts             # ui.* → Canvas 2D rendering
│   │   ├── vec.ts            # vec2/vec3/rgbm constructors
│   │   └── stringify.ts      # stringify() serialization
│   └── types/
│       └── csp.d.ts          # TypeScript types for CSP API
├── public/
│   └── lua/                  # Copied Lua files (build step)
├── index.html
├── vite.config.ts
├── tailwind.config.js
└── package.json
```

---

## Phase 2: CSP API Mocks

### 2.1 Vector/Color Types (vec.ts)

```typescript
export const vec2 = (x = 0, y = 0) => ({ x, y });
export const vec3 = (x = 0, y = 0, z = 0) => ({ x, y, z });
export const rgbm = (r = 0, g = 0, b = 0, mult = 1) => ({ r, g, b, mult });

// Convert rgbm to CSS color
export function rgbmToCSS(c: RGBM, alpha = 1): string {
  return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${alpha * c.mult})`;
}
```

### 2.2 UI Namespace (ui.ts)

The ui.* mock is the core of the web port. It renders to Canvas 2D.

**State Management:**
```typescript
class UIContext {
  canvas: HTMLCanvasElement;
  ctx: CanvasRenderingContext2D;
  cursor: Vec2 = { x: 0, y: 0 };
  mousePos: Vec2 = { x: 0, y: 0 };
  mouseDown: boolean[] = [false, false, false];
  mouseClicked: boolean[] = [false, false, false];
  fontStack: string[] = ['14px monospace'];
  colorStack: RGBM[] = [];
  path: Vec2[] = [];
}
```

**Drawing Functions:**
```typescript
// ui.drawLine(p1, p2, color, thickness)
drawLine(p1: Vec2, p2: Vec2, color: RGBM, thickness = 1) {
  this.ctx.strokeStyle = rgbmToCSS(color);
  this.ctx.lineWidth = thickness;
  this.ctx.beginPath();
  this.ctx.moveTo(p1.x, p1.y);
  this.ctx.lineTo(p2.x, p2.y);
  this.ctx.stroke();
}

// ui.drawRect(p1, p2, color, radius, thickness)
drawRect(p1: Vec2, p2: Vec2, color: RGBM, radius = 0, thickness = 1) {
  this.ctx.strokeStyle = rgbmToCSS(color);
  this.ctx.lineWidth = thickness;
  if (radius > 0) {
    this.roundRect(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y, radius);
    this.ctx.stroke();
  } else {
    this.ctx.strokeRect(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
  }
}

// ui.drawRectFilled(p1, p2, color, radius)
drawRectFilled(p1: Vec2, p2: Vec2, color: RGBM, radius = 0) {
  this.ctx.fillStyle = rgbmToCSS(color);
  if (radius > 0) {
    this.roundRect(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y, radius);
    this.ctx.fill();
  } else {
    this.ctx.fillRect(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
  }
}

// Path-based drawing (for traces)
pathClear() { this.path = []; }
pathLineTo(p: Vec2) { this.path.push(p); }
pathStroke(color: RGBM, closed: boolean, thickness = 1) {
  if (this.path.length < 2) return;
  this.ctx.strokeStyle = rgbmToCSS(color);
  this.ctx.lineWidth = thickness;
  this.ctx.beginPath();
  this.ctx.moveTo(this.path[0].x, this.path[0].y);
  for (let i = 1; i < this.path.length; i++) {
    this.ctx.lineTo(this.path[i].x, this.path[i].y);
  }
  if (closed) this.ctx.closePath();
  this.ctx.stroke();
}
```

**Text Functions:**
```typescript
// ui.text(str)
text(str: string) {
  this.ctx.fillStyle = rgbmToCSS(this.currentColor());
  this.ctx.font = this.currentFont();
  this.ctx.fillText(str, this.cursor.x, this.cursor.y + 12);
  this.cursor.y += 16; // Line height
}

// ui.measureText(str) -> vec2
measureText(str: string): Vec2 {
  this.ctx.font = this.currentFont();
  const metrics = this.ctx.measureText(str);
  return { x: metrics.width, y: 14 }; // Approximate height
}

// ui.dwriteDrawTextClipped(text, fontSize, p1, p2, alignX, alignY, wrap, color)
dwriteDrawTextClipped(text: string, fontSize: number, p1: Vec2, p2: Vec2,
                       alignX: number, alignY: number, wrap: boolean, color: RGBM) {
  this.ctx.save();
  this.ctx.beginPath();
  this.ctx.rect(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
  this.ctx.clip();

  this.ctx.font = `${fontSize}px monospace`;
  this.ctx.fillStyle = rgbmToCSS(color);
  this.ctx.textAlign = alignX < 0.5 ? 'left' : alignX > 0.5 ? 'right' : 'center';
  this.ctx.textBaseline = alignY < 0.5 ? 'top' : alignY > 0.5 ? 'bottom' : 'middle';

  const x = p1.x + (p2.x - p1.x) * alignX;
  const y = p1.y + (p2.y - p1.y) * alignY;
  this.ctx.fillText(text, x, y);
  this.ctx.restore();
}
```

**Input Functions:**
```typescript
mousePos(): Vec2 { return this.mousePos; }
mouseClicked(button = 0): boolean { return this.mouseClicked[button]; }
mouseDown(button = 0): boolean { return this.mouseDown[button]; }
mouseWheel(): number { return this._wheelDelta; }
rectHovered(p1: Vec2, p2: Vec2): boolean {
  const m = this.mousePos;
  return m.x >= p1.x && m.x <= p2.x && m.y >= p1.y && m.y <= p2.y;
}
```

### 2.3 AC Namespace (ac.ts)

Minimal mock for web-only mode (no live car data):

```typescript
export const ac = {
  // Returns null car (web mode has no live car)
  getCar: (idx: number) => null,

  // Mock sim with default track length
  getSim: () => ({
    trackLengthM: 5000,
    dt: 1/60,
    isPaused: false,
    isReplayActive: false,
  }),

  getTrackID: () => "web_viewer",
  getCarID: () => "csv_import",

  // Storage backed by localStorage
  storage: createStorageProxy(),

  // Logging
  log: (msg: string) => console.log('[AC]', msg),
  warn: (msg: string) => console.warn('[AC]', msg),
  error: (msg: string) => console.error('[AC]', msg),

  // Stubs
  setMessage: () => {},
  setClipboardText: (text: string) => navigator.clipboard.writeText(text),
  readMemoryMappedFile: () => null,
};
```

### 2.4 IO Namespace (vfs.ts)

Virtual filesystem with drag-drop CSV support:

```typescript
class VirtualFS {
  files: Map<string, string> = new Map();

  addFile(path: string, content: string) {
    this.files.set(this.normalize(path), content);
  }

  open(path: string, mode: string) {
    const norm = this.normalize(path);
    if (mode.includes('r')) {
      const content = this.files.get(norm);
      if (!content) return null;
      return new VFSHandle(content);
    }
    // Write mode
    return new VFSWriteHandle(norm, this);
  }

  exists(path: string): boolean {
    return this.files.has(this.normalize(path));
  }
}
```

---

## Phase 3: Lua Engine Integration

### 3.1 wasmoon Setup (engine.ts)

```typescript
import { LuaFactory, LuaEngine } from 'wasmoon';

let lua: LuaEngine | null = null;

export async function initLua(): Promise<LuaEngine> {
  const factory = new LuaFactory();
  lua = await factory.createEngine();

  // Register all global mocks
  lua.global.set('ac', ac);
  lua.global.set('ui', ui);
  lua.global.set('io', vfs);
  lua.global.set('vec2', vec2);
  lua.global.set('vec3', vec3);
  lua.global.set('rgbm', rgbm);
  lua.global.set('rgb', rgb);
  lua.global.set('stringify', stringify);
  lua.global.set('bit', bit);
  lua.global.set('math', extendedMath);
  lua.global.set('__dirname', '/lua');

  return lua;
}
```

### 3.2 Lua File Loading (loader.ts)

Load Lua files from the virtual filesystem or bundled assets:

```typescript
// Preload all required Lua files
const LUA_FILES = [
  'lib/lap.lua',
  'lib/lap_csv_parser.lua',
  'lib/core/scoring.lua',
  'lib/core/settings.lua',
  'lib/ui/theme.lua',
  'lib/ui/utils.lua',
  'lib/windows/lap_telemetry.lua',
  'lib/windows/corner_analysis.lua',
];

export async function loadLuaFiles(lua: LuaEngine) {
  for (const file of LUA_FILES) {
    const content = await fetch(`/lua/${file}`).then(r => r.text());
    vfs.addFile(file, content);
  }

  // Setup require() to use VFS
  await lua.doString(`
    package.path = "/lua/?.lua;/lua/lib/?.lua"
    local origRequire = require
    function require(modname)
      local path = modname:gsub("%.", "/") .. ".lua"
      -- Try loading from VFS
      local f = io.open(path, "r")
      if f then
        local content = f:read("*a")
        f:close()
        local fn = load(content, path)
        if fn then
          local result = fn()
          package.loaded[modname] = result
          return result
        end
      end
      return origRequire(modname)
    end
  `);
}
```

---

## Phase 4: React App Shell

### 4.1 Main App (App.tsx)

```tsx
export function App() {
  const [laps, setLaps] = useState<LuaLap[]>([]);
  const [selectedLap, setSelectedLap] = useState<LuaLap | null>(null);
  const [referenceLap, setReferenceLap] = useState<LuaLap | null>(null);

  const handleFileDrop = async (files: File[]) => {
    for (const file of files) {
      const content = await file.text();
      vfs.addFile(`tracks/${file.name}`, content);

      // Parse CSV via Lua
      const lap = await lua.doString(`
        local lap = require('lib.lap')
        return lap.fromCSV('tracks/${file.name}')
      `);

      if (lap) {
        setLaps(prev => [...prev, lap]);
        if (!selectedLap) setSelectedLap(lap);
      }
    }
  };

  return (
    <div className="h-screen flex flex-col bg-gray-900">
      <header className="p-4 border-b border-gray-700">
        <h1 className="text-xl text-white">AC Tracer - Telemetry Viewer</h1>
      </header>

      <div className="flex-1 flex">
        <aside className="w-64 p-4 border-r border-gray-700">
          <FileDrop onDrop={handleFileDrop} />
          <LapList laps={laps} selected={selectedLap} onSelect={setSelectedLap} />
        </aside>

        <main className="flex-1 p-4">
          <TelemetryCanvas lap={selectedLap} reference={referenceLap} />
        </main>
      </div>
    </div>
  );
}
```

### 4.2 Canvas Component (Canvas.tsx)

```tsx
export function TelemetryCanvas({ lap, reference }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d')!;
    ui.setCanvas(canvas, ctx);

    // Render loop
    let running = true;
    const render = () => {
      if (!running) return;

      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Call Lua render function
      lua.doString(`
        local telemetry = require('lib.windows.lap_telemetry')
        telemetry.draw(1/60)
      `);

      requestAnimationFrame(render);
    };

    render();
    return () => { running = false; };
  }, [lap, reference]);

  return (
    <canvas
      ref={canvasRef}
      width={1200}
      height={800}
      className="bg-gray-800 rounded"
      onMouseMove={e => ui.handleMouseMove(e)}
      onMouseDown={e => ui.handleMouseDown(e)}
      onMouseUp={e => ui.handleMouseUp(e)}
      onWheel={e => ui.handleWheel(e)}
    />
  );
}
```

---

## Phase 5: Feature Scope

### In Scope (MVP)

1. **CSV Loading**
   - Drag-drop CSV files onto window
   - File picker dialog
   - Support MoTeC format (as-is from lap_csv_parser.lua)

2. **Telemetry View** (lap_telemetry.lua)
   - All 6 trace graphs (Delta-T, Throttle, Brake, Speed, Lat G, Steering)
   - Time axis with grid lines
   - Cursor overlay with values panel
   - Zoom/pan with mouse wheel and drag
   - Reference lap overlay

3. **Corner Analysis** (corner_analysis.lua)
   - Speed comparison graphs
   - Corner scoring
   - Delta indicators

4. **Settings**
   - Unit toggle (km/h vs mph)
   - Trace visibility toggles
   - Persisted to localStorage

### Out of Scope (Future)

- Live car data (requires actual AC connection)
- Checkpoint save/restore
- Audio notifications
- Memory-mapped file reading (cphys DLL)
- Corner recording (requires live position data)

---

## Phase 6: Implementation Tasks

### Week 1: Foundation
- [ ] Bun + Vite + React project setup
- [ ] wasmoon integration and basic Lua execution
- [ ] vec2/vec3/rgbm type mocks
- [ ] Basic ui.* drawing mocks (rect, line, text)

### Week 2: Core Rendering
- [ ] Complete ui.* mock (paths, circles, fonts)
- [ ] Mouse input handling
- [ ] Load lap.lua and lap_csv_parser.lua
- [ ] CSV drag-drop and parsing

### Week 3: Telemetry UI
- [ ] Render lap_telemetry.lua traces
- [ ] Implement cursor interaction
- [ ] Zoom/pan controls
- [ ] Reference lap overlay

### Week 4: Polish
- [ ] Corner analysis view
- [ ] Settings persistence
- [ ] Error handling and loading states
- [ ] Performance optimization

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| wasmoon Lua version differences | High | Test against mock_ac.lua test suite first |
| Canvas 2D performance | Medium | Batch draw calls, use offscreen canvas |
| ui.* API coverage gaps | Medium | Implement on-demand as errors surface |
| Complex path rendering | Low | Canvas 2D paths are well-supported |

---

## Success Criteria

1. **Functional**: Load a MoTeC CSV and see telemetry traces render correctly
2. **Interactive**: Cursor shows values, zoom/pan works
3. **Faithful**: Visual output matches AC in-game rendering
4. **Unchanged Lua**: No modifications to existing ../lib/ files

---

## Next Steps

1. Create `web/` directory structure
2. Initialize Bun + Vite project
3. Implement vec/rgbm types first (needed by everything)
4. Build ui.* mock incrementally, testing with simple Lua scripts
5. Load real lap.lua and verify CSV parsing works
