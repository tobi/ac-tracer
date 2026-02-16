// Lua engine setup with fengari-web
// fengari is a pure-JS Lua 5.3 implementation that works in browsers
import * as fengari from "fengari-web";
import {
  vec2,
  vec3,
  vec4,
  rgb,
  rgbm,
  rgbmColors,
  ui,
  ac,
  vfs,
  bit,
  uiContext,
} from "../mocks";

const { lua, lauxlib, lualib, to_luastring, to_jsstring } = fengari;

let L: any = null; // Lua state
let isInitialized = false;
type LuaEvent = { type: string; payload: unknown };
const luaEventQueue: LuaEvent[] = [];

// List of Lua files to preload
const LUA_FILES = [
  "lib/lap.lua",
  "lib/lap_csv_parser.lua",
  "lib/lap_csv_export.lua",
  "lib/core/scoring.lua",
  "lib/core/settings.lua",
  "lib/core/brake.lua",
  "lib/core/files.lua",
  "lib/core/history.lua",
  "lib/core/background_writer.lua",
  "lib/core/state.lua",
  "lib/sound/notification.lua",
  "lib/ui/theme.lua",
  "lib/ui/utils.lua",
  "lib/ui/wedge.lua",
  "lib/ui/markdown.lua",
  "lib/windows/lap_telemetry.lua",
  "lib/windows/corner_analysis.lua",
  "lib/windows/lap_picker.lua",
];

// Push a JS value onto the Lua stack
// Bridge call counter on globalThis so both old cfunction wrappers and new code share it
declare global { var __bridgeCalls: number; }
globalThis.__bridgeCalls = globalThis.__bridgeCalls ?? 0;

function pushValue(L: any, value: unknown): void {
  if (value === null || value === undefined) {
    lua.lua_pushnil(L);
  } else if (typeof value === "boolean") {
    lua.lua_pushboolean(L, value ? 1 : 0);
  } else if (typeof value === "number") {
    lua.lua_pushnumber(L, value);
  } else if (typeof value === "string") {
    lua.lua_pushstring(L, to_luastring(value));
  } else if (typeof value === "function") {
    // Wrap JS function for Lua
    lua.lua_pushcfunction(L, (L: any) => {
      globalThis.__bridgeCalls++;
      const nargs = lua.lua_gettop(L);
      const args: unknown[] = [];
      for (let i = 1; i <= nargs; i++) {
        args.push(getValue(L, i));
      }
      try {
        const result = (value as Function)(...args);
        if (result !== undefined) {
          pushValue(L, result);
          return 1;
        }
        return 0;
      } catch (e) {
        console.error("[Lua] JS function error:", e);
        return 0;
      }
    });
  } else if (Array.isArray(value)) {
    lua.lua_createtable(L, value.length, 0);
    value.forEach((v, i) => {
      pushValue(L, v);
      lua.lua_rawseti(L, -2, i + 1);
    });
  } else if (typeof value === "object") {
    lua.lua_createtable(L, 0, Object.keys(value as object).length);
    for (const [k, v] of Object.entries(value as object)) {
      lua.lua_pushstring(L, to_luastring(k));
      pushValue(L, v);
      lua.lua_settable(L, -3);
    }
  } else {
    lua.lua_pushnil(L);
  }
}

// Get a value from the Lua stack
function getValue(L: any, index: number): unknown {
  const t = lua.lua_type(L, index);
  switch (t) {
    case lua.LUA_TNIL:
      return null;
    case lua.LUA_TBOOLEAN:
      return lua.lua_toboolean(L, index) !== 0;
    case lua.LUA_TNUMBER:
      return lua.lua_tonumber(L, index);
    case lua.LUA_TSTRING:
      return to_jsstring(lua.lua_tostring(L, index));
    case lua.LUA_TTABLE:
      return getTable(L, index);
    case lua.LUA_TFUNCTION:
      // Return a wrapper that calls the Lua function
      const ref = lauxlib.luaL_ref(L, lua.LUA_REGISTRYINDEX);
      return (...args: unknown[]) => {
        lua.lua_rawgeti(L, lua.LUA_REGISTRYINDEX, ref);
        args.forEach((a) => pushValue(L, a));
        if (lua.lua_pcall(L, args.length, 1, 0) !== lua.LUA_OK) {
          console.error("[Lua] Call error:", to_jsstring(lua.lua_tostring(L, -1)));
          lua.lua_pop(L, 1);
          return undefined;
        }
        const result = getValue(L, -1);
        lua.lua_pop(L, 1);
        return result;
      };
    default:
      return null;
  }
}

// Convert Lua table to JS object/array
function getTable(L: any, index: number): Record<string, unknown> | unknown[] {
  const result: Record<string, unknown> = {};
  let isArray = true;
  let maxIndex = 0;

  // Make index absolute
  if (index < 0) index = lua.lua_gettop(L) + index + 1;

  lua.lua_pushnil(L);
  while (lua.lua_next(L, index) !== 0) {
    const keyType = lua.lua_type(L, -2);
    let key: string | number;

    if (keyType === lua.LUA_TNUMBER) {
      key = lua.lua_tonumber(L, -2);
      if (Number.isInteger(key) && key > 0) {
        maxIndex = Math.max(maxIndex, key as number);
      } else {
        isArray = false;
      }
    } else {
      key = to_jsstring(lua.lua_tostring(L, -2));
      isArray = false;
    }

    result[key] = getValue(L, -1);
    lua.lua_pop(L, 1);
  }

  if (isArray && maxIndex > 0) {
    const arr: unknown[] = [];
    for (let i = 1; i <= maxIndex; i++) {
      arr.push(result[i]);
    }
    return arr;
  }

  return result;
}

// Set a global variable
function setGlobal(name: string, value: unknown): void {
  pushValue(L, value);
  lua.lua_setglobal(L, to_luastring(name));
}

// Initialize the Lua engine
export async function initLua(): Promise<void> {
  if (isInitialized) return;

  console.log("[Lua] Initializing fengari...");

  // Create new Lua state
  L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);

  // Register all globals
  console.log("[Lua] Registering globals...");

  // Vector/color constructors
  setGlobal("vec2", vec2);
  setGlobal("vec3", vec3);
  setGlobal("vec4", vec4);
  setGlobal("rgb", rgb);

  // rgbm with colors table
  const rgbmWithColors = Object.assign(
    (r: number, g: number, b: number, m: number) => rgbm(r, g, b, m),
    { colors: rgbmColors }
  );
  setGlobal("rgbm", rgbmWithColors);

  // Core namespaces
  setGlobal("ac", ac);
  setGlobal("ui", ui);
  setGlobal("bit", bit);
  setGlobal("__dirname", "/lua");
  setGlobal("_web_emit", (type: string, payload?: unknown) => {
    luaEventQueue.push({ type, payload });
    return true;
  });

  // Set up stringify as a Lua table with methods (needs metatable for __call)
  await doString(`
    stringify = {}

    local function serializeValue(v, seen)
      if v == nil then return "nil" end
      local t = type(v)
      if t == "string" then
        return string.format("%q", v)
      elseif t == "number" then
        return tostring(v)
      elseif t == "boolean" then
        return tostring(v)
      elseif t == "table" then
        if seen[v] then return "..." end
        seen[v] = true
        local parts = {}
        local isArray = true
        local n = 0
        for k in pairs(v) do
          n = n + 1
          if type(k) ~= "number" or k ~= n then isArray = false end
        end
        if isArray then
          for i, val in ipairs(v) do
            parts[i] = serializeValue(val, seen)
          end
          return "{" .. table.concat(parts, ",") .. "}"
        else
          for k, val in pairs(v) do
            local key = type(k) == "string" and k or "[" .. serializeValue(k, seen) .. "]"
            table.insert(parts, key .. "=" .. serializeValue(val, seen))
          end
          return "{" .. table.concat(parts, ",") .. "}"
        end
      end
      return "nil"
    end

    stringify.binary = function(data)
      return serializeValue(data, {})
    end

    stringify.parse = function(str)
      if not str or str == "" then return nil end
      local fn = load("return " .. str)
      if fn then
        local ok, result = pcall(fn)
        if ok then return result end
      end
      return nil
    end

    stringify.tryParse = function(str, default)
      local result = stringify.parse(str)
      return result or default
    end

    setmetatable(stringify, {
      __call = function(t, data)
        return serializeValue(data, {})
      end
    })
  `);

  // Provide ffi stub (some modules try to load it)
  await doString(`
    package.preload['ffi'] = function()
      return {
        cdef = function() end,
        cast = function(t, v) return v end,
        new = function(t, ...) return {} end,
        C = setmetatable({}, {
          __index = function(t, k)
            return function() return nil end
          end
        }),
      }
    end
  `);

  // Create empty io table (will be populated by Lua code)
  setGlobal("io", {});

  // Override print
  setGlobal("print", (...args: unknown[]) => {
    console.log("[Lua]", ...args);
  });

  // Register VFS helper functions FIRST (before io.open is redefined)
  setGlobal("_vfs_read", (path: string) => vfs.getFile(path) || null);
  setGlobal("_vfs_write", (path: string, content: string) => {
    vfs.addFile(path, content);
    return true;
  });
  setGlobal("_vfs_exists", (path: string) => vfs.getFile(path) !== undefined);
  setGlobal("_vfs_dir_exists", (path: string) => {
    const files = vfs.listFiles();
    const prefix = path.endsWith("/") ? path : path + "/";
    return files.some((f) => f.startsWith(prefix)) || path === "." || path === "";
  });
  setGlobal("_vfs_create_dir", () => true);
  setGlobal("_vfs_scan_dir", (path: string, pattern?: string) => {
    const files = vfs.listFiles();
    const prefix = path === "." || path === "" ? "" : path.replace(/\\/g, "/") + "/";
    let suffix: string | null = null;
    if (pattern && pattern.startsWith("*.")) {
      suffix = pattern.substring(1).toLowerCase();
    }
    const results: string[] = [];
    for (const f of files) {
      if (f.startsWith(prefix)) {
        const rest = f.substring(prefix.length);
        if (!rest.includes("/")) {
          if (!suffix || rest.toLowerCase().endsWith(suffix)) {
            results.push(rest);
          }
        }
      }
    }
    return results.length > 0 ? results : null;
  });

  // Extended math functions
  await doString(`
    math.clamp = function(v, min, max)
      if v < min then return min end
      if v > max then return max end
      return v
    end

    math.sign = function(v)
      if v > 0 then return 1 end
      if v < 0 then return -1 end
      return 0
    end

    math.lerp = function(a, b, t)
      return a + (b - a) * t
    end

    math.saturate = function(v)
      return math.clamp(v, 0, 1)
    end

    math.round = function(v, decimals)
      local mult = 10 ^ (decimals or 0)
      return math.floor(v * mult + 0.5) / mult
    end

    os.preciseClock = os.clock
  `);

  // Setup custom IO functions - create io table from scratch
  await doString(`
    -- Create io table if it doesn't exist
    io = io or {}

    -- Virtual filesystem open function
    local function vfs_open(path, mode)
      mode = mode or "r"
      local content = _vfs_read(path)
      if string.find(mode, "r") and not content then
        return nil
      end

      local handle = {
        _cursor = 1,
        _path = path,
        _mode = mode,
        _buffer = string.find(mode, "w") and "" or (content or ""),
      }

      function handle:read(what)
        if what == "*a" then
          local result = string.sub(self._buffer, self._cursor)
          self._cursor = string.len(self._buffer) + 1
          return result
        elseif what == "*l" then
          if self._cursor > string.len(self._buffer) then return nil end
          local nl = string.find(self._buffer, "\\n", self._cursor, true)
          local line
          if nl then
            line = string.sub(self._buffer, self._cursor, nl - 1)
            self._cursor = nl + 1
          else
            line = string.sub(self._buffer, self._cursor)
            self._cursor = string.len(self._buffer) + 1
          end
          if string.sub(line, -1) == "\\r" then line = string.sub(line, 1, -2) end
          return line
        elseif type(what) == "number" then
          local result = string.sub(self._buffer, self._cursor, self._cursor + what - 1)
          self._cursor = self._cursor + what
          return result ~= "" and result or nil
        end
        return self:read("*l")
      end

      function handle:lines()
        return function()
          return self:read("*l")
        end
      end

      function handle:write(data)
        if string.find(self._mode, "w") or string.find(self._mode, "a") then
          self._buffer = self._buffer .. tostring(data)
          return true
        end
        return false
      end

      function handle:seek(whence, offset)
        offset = offset or 0
        if whence == "set" then
          self._cursor = offset + 1
        elseif whence == "cur" then
          self._cursor = self._cursor + offset
        elseif whence == "end" then
          self._cursor = string.len(self._buffer) + 1 + offset
        end
        self._cursor = math.max(1, math.min(string.len(self._buffer) + 1, self._cursor))
        return self._cursor - 1
      end

      function handle:close()
        if string.find(self._mode, "w") or string.find(self._mode, "a") then
          _vfs_write(self._path, self._buffer)
        end
        return true
      end

      return handle
    end

    io.open = vfs_open

    io.exists = function(path)
      return _vfs_exists(path)
    end

    io.fileExists = io.exists

    io.dirExists = function(path)
      return _vfs_dir_exists(path)
    end

    io.createDir = function(path)
      return _vfs_create_dir(path)
    end

    io.scanDir = function(path, pattern)
      return _vfs_scan_dir(path, pattern)
    end

    io.fileSize = function(path)
      local content = _vfs_read(path)
      return content and string.len(content) or -1
    end
  `);

  // Setup custom require
  await doString(`
    local loaded = {}

    local origRequire = require
    function require(modname)
      if loaded[modname] then
        return loaded[modname]
      end

      -- Convert module name to path
      local path = modname:gsub("%.", "/") .. ".lua"

      -- Try to open from VFS
      local f = io.open(path, "r")
      if f then
        local content = f:read("*a")
        f:close()

        local fn, err = load(content, "@" .. path)
        if fn then
          local result = fn()
          loaded[modname] = result or true
          return loaded[modname]
        else
          error("Error loading module '" .. modname .. "': " .. (err or "unknown"))
        end
      end

      -- Fallback
      return origRequire(modname)
    end
  `);

  isInitialized = true;
  console.log("[Lua] Engine initialized");
}

let filesLoaded = false;

// Load Lua source files into the VFS
export async function loadLuaFiles(): Promise<void> {
  if (filesLoaded) {
    console.log("[Lua] Files already loaded, skipping...");
    return;
  }

  console.log("[Lua] Loading Lua files from server...");

  // Load all files in parallel for speed
  const promises = LUA_FILES.map(async (file) => {
    try {
      const response = await fetch(`/lua/${file}`);
      if (response.ok) {
        const content = await response.text();
        vfs.addFile(file, content);
        console.log(`[Lua] Loaded ${file}`);
        return true;
      } else {
        console.warn(`[Lua] Failed to load ${file}: ${response.status}`);
        return false;
      }
    } catch (err) {
      console.warn(`[Lua] Error loading ${file}:`, err);
      return false;
    }
  });

  await Promise.all(promises);
  filesLoaded = true;
  console.log("[Lua] All Lua files loaded");
}

// Execute Lua code
export async function doString(code: string): Promise<unknown> {
  if (!L) {
    throw new Error("Lua engine not initialized");
  }

  const status = lauxlib.luaL_dostring(L, to_luastring(code));
  if (status !== lua.LUA_OK) {
    const errMsg = to_jsstring(lua.lua_tostring(L, -1));
    lua.lua_pop(L, 1);
    throw new Error(`Lua error: ${errMsg}`);
  }

  // Get return value if any
  if (lua.lua_gettop(L) > 0) {
    const result = getValue(L, -1);
    lua.lua_settop(L, 0);
    return result;
  }

  return undefined;
}

// Set the canvas for UI rendering
export function setCanvas(canvas: HTMLCanvasElement): void {
  uiContext.setCanvas(canvas);
}

// Begin a new frame (reset per-frame state)
export function beginFrame(): void {
  uiContext.beginFrame();
}

// Get the UI context for event handling
export { uiContext };

// Bridge call counting (number of JS function calls from Lua per frame)
export function getBridgeCalls(): number {
  return globalThis.__bridgeCalls;
}
export function resetBridgeCalls(): void {
  globalThis.__bridgeCalls = 0;
}

export function drainLuaEvents(): LuaEvent[] {
  const events = [...luaEventQueue];
  luaEventQueue.length = 0;
  return events;
}

// Get the VFS for file operations
export { vfs };
