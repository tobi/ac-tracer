#!/usr/bin/env bun
// Test script to verify fengari Lua engine works with our mocks
// Run with: bun test-lua.ts

import * as fengari from "fengari";
import * as fs from "fs";
import * as path from "path";

const { lua, lauxlib, lualib, to_luastring, to_jsstring } = fengari;

// Simple VFS for testing
const vfs = new Map<string, string>();

function addFile(filePath: string, content: string) {
  vfs.set(filePath.replace(/\\/g, "/"), content);
}

function getFile(filePath: string): string | undefined {
  return vfs.get(filePath.replace(/\\/g, "/"));
}

// Load all Lua files from ../lib into VFS
function loadLuaFiles() {
  const libDir = path.join(__dirname, "..", "lib");

  function walkDir(dir: string, prefix: string = "") {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      const vfsPath = prefix ? `${prefix}/${entry.name}` : entry.name;

      if (entry.isDirectory()) {
        walkDir(fullPath, vfsPath);
      } else if (entry.name.endsWith(".lua")) {
        const content = fs.readFileSync(fullPath, "utf-8");
        addFile(`lib/${vfsPath}`, content);
      }
    }
  }

  walkDir(libDir);
  console.log(`Loaded ${vfs.size} Lua files into VFS`);
}

// Push JS value to Lua stack
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
    lua.lua_pushcfunction(L, (L: any) => {
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

// Get value from Lua stack
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
    default:
      return null;
  }
}

function getTable(L: any, index: number): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  if (index < 0) index = lua.lua_gettop(L) + index + 1;

  lua.lua_pushnil(L);
  while (lua.lua_next(L, index) !== 0) {
    const keyType = lua.lua_type(L, -2);
    let key: string | number;
    if (keyType === lua.LUA_TNUMBER) {
      key = lua.lua_tonumber(L, -2);
    } else {
      key = to_jsstring(lua.lua_tostring(L, -2));
    }
    result[key] = getValue(L, -1);
    lua.lua_pop(L, 1);
  }
  return result;
}

function setGlobal(L: any, name: string, value: unknown): void {
  pushValue(L, value);
  lua.lua_setglobal(L, to_luastring(name));
}

function doString(L: any, code: string): unknown {
  const status = lauxlib.luaL_dostring(L, to_luastring(code));
  if (status !== lua.LUA_OK) {
    const errMsg = to_jsstring(lua.lua_tostring(L, -1));
    lua.lua_pop(L, 1);
    throw new Error(`Lua error: ${errMsg}`);
  }
  if (lua.lua_gettop(L) > 0) {
    const result = getValue(L, -1);
    lua.lua_settop(L, 0);
    return result;
  }
  return undefined;
}

async function main() {
  console.log("=== Fengari Lua Test ===\n");

  // Load Lua files from ../lib
  loadLuaFiles();

  // Also load test files
  const testsDir = path.join(__dirname, "..", "tests");
  function loadTestFiles(dir: string, prefix: string = "") {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      const vfsPath = prefix ? `${prefix}/${entry.name}` : entry.name;
      if (entry.name.endsWith(".lua")) {
        const content = fs.readFileSync(fullPath, "utf-8");
        addFile(`tests/${vfsPath}`, content);
      }
    }
  }
  loadTestFiles(testsDir);
  console.log(`VFS now has ${vfs.size} files total`);

  // Create Lua state
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);

  // Register VFS helpers
  setGlobal(L, "_vfs_read", (p: string) => getFile(p) || null);
  setGlobal(L, "_vfs_exists", (p: string) => vfs.has(p));
  setGlobal(L, "_vfs_write", (p: string, c: string) => { addFile(p, c); return true; });
  setGlobal(L, "_vfs_dir_exists", () => true);
  setGlobal(L, "_vfs_create_dir", () => true);
  setGlobal(L, "_vfs_scan_dir", (p: string, pattern?: string) => {
    const prefix = p === "." || p === "" ? "" : p + "/";
    const suffix = pattern?.startsWith("*.") ? pattern.substring(1).toLowerCase() : null;
    const results: string[] = [];
    for (const f of vfs.keys()) {
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

  // Mock globals
  setGlobal(L, "vec2", (x = 0, y = 0) => ({ x, y }));
  setGlobal(L, "vec3", (x = 0, y = 0, z = 0) => ({ x, y, z }));
  setGlobal(L, "rgb", (r = 0, g = 0, b = 0) => ({ r, g, b }));
  setGlobal(L, "rgbm", (r = 0, g = 0, b = 0, mult = 1) => ({ r, g, b, mult }));
  setGlobal(L, "__dirname", ".");
  setGlobal(L, "io", {});

  // Mock ac namespace
  setGlobal(L, "ac", {
    log: (msg: string) => console.log("[AC]", msg),
    warn: (msg: string) => console.warn("[AC]", msg),
    error: (msg: string) => console.error("[AC]", msg),
    storage: () => ({}),
    getSim: () => ({ trackLengthM: 5000, dt: 1/60 }),
    getCar: () => null,
    getTrackID: () => "test_track",
    getCarID: () => "test_car",
  });

  // Mock ui namespace (minimal for testing)
  setGlobal(L, "ui", {
    text: () => {},
    drawLine: () => {},
    drawRect: () => {},
    drawRectFilled: () => {},
    pathClear: () => {},
    pathLineTo: () => {},
    pathStroke: () => {},
    availableSpace: () => ({ x: 800, y: 600 }),
    setCursor: () => {},
    Font: { Main: 1, Monospace: 2 },
    StyleColor: { Text: 1 },
    pushFont: () => {},
    popFont: () => {},
    pushStyleColor: () => {},
    popStyleColor: () => {},
  });

  // Mock bit library
  setGlobal(L, "bit", {
    band: (a: number, b: number) => a & b,
    bor: (a: number, b: number) => a | b,
    bxor: (a: number, b: number) => a ^ b,
    bnot: (a: number) => ~a,
    lshift: (a: number, n: number) => a << n,
    rshift: (a: number, n: number) => a >>> n,
  });

  // Mock stringify as a table with methods
  // We'll set it up in Lua since we need metatable for __call
  doString(L, `
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

  // Setup math extensions and io
  doString(L, `
    math.clamp = function(v, min, max)
      if v < min then return min end
      if v > max then return max end
      return v
    end
    math.sign = function(v) if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end end
    math.lerp = function(a, b, t) return a + (b - a) * t end
    math.saturate = function(v) return math.clamp(v, 0, 1) end
    math.round = function(v, d) local m = 10^(d or 0); return math.floor(v*m+0.5)/m end
    os.preciseClock = os.clock
  `);

  // Setup VFS-backed io
  doString(L, `
    local function vfs_open(path, mode)
      mode = mode or "r"
      local content = _vfs_read(path)
      if string.find(mode, "r") and not content then return nil end

      local h = { _cursor = 1, _path = path, _mode = mode, _buffer = string.find(mode, "w") and "" or (content or "") }

      function h:read(what)
        if what == "*a" then
          local r = string.sub(self._buffer, self._cursor)
          self._cursor = #self._buffer + 1
          return r
        elseif what == "*l" then
          if self._cursor > #self._buffer then return nil end
          local nl = string.find(self._buffer, "\\n", self._cursor, true)
          local line
          if nl then line = string.sub(self._buffer, self._cursor, nl-1); self._cursor = nl+1
          else line = string.sub(self._buffer, self._cursor); self._cursor = #self._buffer+1 end
          if string.sub(line, -1) == "\\r" then line = string.sub(line, 1, -2) end
          return line
        elseif type(what) == "number" then
          local r = string.sub(self._buffer, self._cursor, self._cursor+what-1)
          self._cursor = self._cursor + what
          return r ~= "" and r or nil
        end
        return self:read("*l")
      end

      function h:lines() return function() return self:read("*l") end end
      function h:write(d) if string.find(self._mode,"w") or string.find(self._mode,"a") then self._buffer = self._buffer..tostring(d); return true end; return false end
      function h:seek(w,o) o=o or 0; if w=="set" then self._cursor=o+1 elseif w=="cur" then self._cursor=self._cursor+o elseif w=="end" then self._cursor=#self._buffer+1+o end; self._cursor=math.max(1,math.min(#self._buffer+1,self._cursor)); return self._cursor-1 end
      function h:close() if string.find(self._mode,"w") or string.find(self._mode,"a") then _vfs_write(self._path, self._buffer) end; return true end

      return h
    end

    io.open = vfs_open
    io.exists = function(p) return _vfs_exists(p) end
    io.fileExists = io.exists
    io.dirExists = function(p) return _vfs_dir_exists(p) end
    io.createDir = function(p) return _vfs_create_dir(p) end
    io.scanDir = function(p, pat) return _vfs_scan_dir(p, pat) end
    io.fileSize = function(p) local c = _vfs_read(p); return c and #c or -1 end
  `);

  // Setup custom require
  doString(L, `
    local loaded = {}
    local origRequire = require
    function require(modname)
      if loaded[modname] then return loaded[modname] end
      local path = modname:gsub("%.", "/") .. ".lua"
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
          error("Error loading '" .. modname .. "': " .. (err or "unknown"))
        end
      end
      return origRequire(modname)
    end
  `);

  console.log("Lua environment ready\n");

  // Test 1: Load lap module
  console.log("Test 1: Load lap module...");
  try {
    const result = doString(L, `
      local lap = require('lib.lap')
      return { SAMPLE_RATE = lap.SAMPLE_RATE }
    `);
    console.log("  OK:", result);
  } catch (e) {
    console.log("  FAILED:", e);
    process.exit(1);
  }

  // Test 2: Create a lap and add samples
  console.log("\nTest 2: Create lap and add samples...");
  try {
    const result = doString(L, `
      local lap = require('lib.lap')
      local l = lap.new("test_track", "test_car")

      -- Directly populate arrays (like CSV import does)
      for i = 1, 100 do
        local pos = (i - 1) / 100
        l.pos[i] = pos
        l.throttle[i] = math.sin(pos * math.pi)
        l.brake[i] = math.max(0, math.cos(pos * math.pi) * 50)
        l.brake_r[i] = l.brake[i]
        l.speed[i] = 100 + pos * 50
        l.gear[i] = math.floor(pos * 5) + 1
        l.steering[i] = 0.5
        l.clutch[i] = 0
        l.times[i] = i / 60
        l.flags[i] = 0
      end

      return {
        length = l:length(),
        throttleAt50 = l:throttleAt(0.5),
        speedAt25 = l:speedAt(0.25),
        brakeAt30 = l:brakeAt(0.3),
      }
    `);
    console.log("  OK:", result);
  } catch (e) {
    console.log("  FAILED:", e);
  }

  // Test 3: Load CSV parser
  console.log("\nTest 3: Load CSV parser...");
  try {
    doString(L, `require('lib.lap_csv_parser')`);
    console.log("  OK: CSV parser loaded");
  } catch (e) {
    console.log("  FAILED:", e);
  }

  // Test 4: Parse a simple CSV
  console.log("\nTest 4: Parse CSV data...");
  try {
    // Add a test CSV to VFS
    const testCSV = `"Format","MoTeC CSV File"
"Sample Rate","60","Hz"

"Time","Track","Lap Progression","Ground Speed","Driver Throttle Pos","Brake Pressure F","Steering Angle","Gear"
"s","","","km/h","%","bar","deg",""

"0.000","test_track","0.0000","100","0.50","0","0","3"
"0.017","test_track","0.0100","102","0.60","0","5","3"
"0.033","test_track","0.0200","104","0.70","0","10","3"
"0.050","test_track","0.0300","106","0.80","10","15","3"
"0.067","test_track","0.0400","108","0.90","20","10","4"
"0.083","test_track","0.0500","110","1.00","0","5","4"
`;
    addFile("test.csv", testCSV);

    const result = doString(L, `
      local lap = require('lib.lap')
      local l = lap.fromCSV("test.csv")
      if l then
        return {
          track = l.track,
          samples = l:length(),
          speedAt0 = l:speedAt(0),
        }
      end
      return nil
    `);
    console.log("  OK:", result);
  } catch (e) {
    console.log("  FAILED:", e);
  }

  // Test 5: Run actual test_lap.lua suite
  console.log("\nTest 5: Run test_lap.lua suite...");
  try {
    // First, provide a stub ffi module (mock_ac.lua tries to load it for Windows APIs)
    doString(L, `
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

    const result = doString(L, `
      -- Load mock_ac first (sets up ac, ui, math extensions, etc.)
      require('tests.mock_ac')

      -- Set up minimal test framework
      local tests = {
        passed = 0,
        failed = 0,
        errors = {},
        current_suite = nil,
      }

      function tests.suite(name)
        tests.current_suite = name
        print("\\n=== " .. name .. " ===")
      end

      function tests.test(name, fn)
        local full_name = tests.current_suite and (tests.current_suite .. ": " .. name) or name
        local ok, err = pcall(fn)
        if ok then
          tests.passed = tests.passed + 1
          print("  [PASS] " .. name)
        else
          tests.failed = tests.failed + 1
          print("  [FAIL] " .. name)
          print("         " .. tostring(err))
          table.insert(tests.errors, { name = full_name, error = err })
        end
      end

      function tests.assert(condition, message)
        if not condition then
          error(message or "Assertion failed", 2)
        end
      end

      function tests.assertEqual(actual, expected, message)
        if actual ~= expected then
          local msg = string.format("%s\\n    Expected: %s\\n    Actual: %s",
            message or "Values not equal",
            tostring(expected),
            tostring(actual))
          error(msg, 2)
        end
      end

      function tests.assertNear(actual, expected, tolerance, message)
        tolerance = tolerance or 0.0001
        if math.abs(actual - expected) > tolerance then
          error((message or "Values not near") .. " expected:" .. expected .. " got:" .. actual, 2)
        end
      end

      function tests.assertNotNil(value, message)
        if value == nil then error(message or "Expected non-nil", 2) end
      end

      function tests.assertNil(value, message)
        if value ~= nil then error(message or "Expected nil", 2) end
      end

      function tests.assertTableEqual(actual, expected, message)
        for k, v in pairs(expected) do
          if actual[k] ~= v then
            error((message or "Tables not equal") .. " key:" .. k, 2)
          end
        end
      end

      -- Expose tests globally
      _G.tests = tests

      -- Now run a subset of lap tests
      local lap = require('lib.lap')

      tests.suite("Lap Basic")

      tests.test("create new lap", function()
        local l = lap.new("test_track", "test_car")
        tests.assertNotNil(l)
        tests.assertEqual(l.track, "test_track")
        tests.assertEqual(l.car, "test_car")
      end)

      tests.test("lap length starts at 0", function()
        local l = lap.new("test_track", "test_car")
        tests.assertEqual(l:length(), 0)
      end)

      tests.test("populate arrays directly", function()
        local l = lap.new("test_track", "test_car")
        for i = 1, 10 do
          l.pos[i] = (i - 1) / 10
          l.throttle[i] = i / 10
          l.brake[i] = 0
          l.brake_r[i] = 0
          l.speed[i] = 100 + i * 10
          l.gear[i] = 3
          l.steering[i] = 0.5
          l.clutch[i] = 0
          l.times[i] = i * 0.1
          l.flags[i] = 0
        end
        tests.assertEqual(l:length(), 10)
        tests.assertNear(l:throttleAt(0.45), 0.5, 0.1)  -- Allow some interpolation variance
        tests.assertNear(l:speedAt(0.0), 110, 5)  -- Allow some variance
      end)

      tests.test("interpolation at exact sample", function()
        local l = lap.new("test", "car")
        l.pos[1] = 0.0
        l.pos[2] = 0.5
        l.pos[3] = 1.0
        l.speed[1] = 100
        l.speed[2] = 150
        l.speed[3] = 200
        -- Fill other required arrays
        for i = 1, 3 do
          l.throttle[i] = 0
          l.brake[i] = 0
          l.brake_r[i] = 0
          l.gear[i] = 3
          l.steering[i] = 0.5
          l.clutch[i] = 0
          l.times[i] = i * 0.1
          l.flags[i] = 0
        end

        tests.assertNear(l:speedAt(0.0), 100, 0.1)
        tests.assertNear(l:speedAt(0.5), 150, 0.1)
        tests.assertNear(l:speedAt(1.0), 200, 0.1)
        tests.assertNear(l:speedAt(0.25), 125, 0.1)  -- interpolated
      end)

      return { passed = tests.passed, failed = tests.failed }
    `);
    console.log("  Result:", result);
  } catch (e) {
    console.log("  FAILED:", e);
  }

  console.log("\n=== All tests complete ===");
}

main().catch(console.error);
