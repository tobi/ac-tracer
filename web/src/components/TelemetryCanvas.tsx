import React, { useRef, useEffect, useCallback } from "react";
import {
  doString,
  setCanvas,
  uiContext,
  getBridgeCalls,
  resetBridgeCalls,
} from "../lua/engine";

// Performance tracking
const perf = {
  frameCount: 0,
  totalDrawMs: 0,
  minDrawMs: Infinity,
  maxDrawMs: 0,
  lastReportTime: 0,
  drawCalls: 0,
  reportIntervalMs: 3000,
};

function resetPerfCounters() {
  perf.frameCount = 0;
  perf.totalDrawMs = 0;
  perf.minDrawMs = Infinity;
  perf.maxDrawMs = 0;
  perf.drawCalls = 0;
  perf.lastReportTime = performance.now();
}

function reportPerf() {
  const now = performance.now();
  const elapsed = now - perf.lastReportTime;
  if (elapsed < perf.reportIntervalMs || perf.frameCount === 0) return false;

  const avgMs = perf.totalDrawMs / perf.frameCount;
  const fps = (perf.frameCount / elapsed) * 1000;
  const avgBridgeCalls = perf.drawCalls / perf.frameCount;
  console.log(
    `[perf] ${fps.toFixed(1)} fps | draw: ${avgMs.toFixed(1)}ms avg, ${perf.minDrawMs.toFixed(1)}ms min, ${perf.maxDrawMs.toFixed(1)}ms max | ${avgBridgeCalls.toFixed(0)} bridge calls/frame | ${perf.frameCount} frames`
  );
  resetPerfCounters();
  return true;
}

interface TelemetryCanvasProps {
  lapPath: string;
  referencePath: string | null;
  showCornerAnalysis: boolean;
}

export default function TelemetryCanvas({
  lapPath,
  referencePath,
  showCornerAnalysis,
}: TelemetryCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const frameRef = useRef<number>(0);
  const lapsLoadedRef = useRef<string>("");

  // Resize canvas to fill container
  const resizeCanvas = useCallback(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;

    const rect = container.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;

    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    canvas.style.width = `${rect.width}px`;
    canvas.style.height = `${rect.height}px`;

    const ctx = canvas.getContext("2d");
    if (ctx) {
      ctx.scale(dpr, dpr);
    }
  }, []);

  useEffect(() => {
    resizeCanvas();
    window.addEventListener("resize", resizeCanvas);
    return () => window.removeEventListener("resize", resizeCanvas);
  }, [resizeCanvas]);

  // Load laps into Lua globals when paths change
  useEffect(() => {
    const key = `${lapPath}|${referencePath ?? ""}`;
    if (lapsLoadedRef.current === key) return;

    (async () => {
      try {
        const refLine = referencePath
          ? `_web_ref_lap = lap.fromCSV('${referencePath}')`
          : `_web_ref_lap = nil`;

        await doString(`
          local lap = require('lib.lap')
          _web_selected_lap = lap.fromCSV('${lapPath}')
          ${refLine}

          local function parseCSVLine(line)
            local fields = {}
            local field = ""
            local inQuotes = false
            local i = 1

            while i <= #line do
              local c = line:sub(i, i)
              if inQuotes then
                if c == '"' then
                  if line:sub(i + 1, i + 1) == '"' then
                    field = field .. '"'
                    i = i + 1
                  else
                    inQuotes = false
                  end
                else
                  field = field .. c
                end
              else
                if c == '"' then
                  inQuotes = true
                elseif c == "," then
                  table.insert(fields, field)
                  field = ""
                else
                  field = field .. c
                end
              end
              i = i + 1
            end

            table.insert(fields, field)
            return fields
          end

          local function loadCornersForTrack(trackId)
            local corners = {}
            if not trackId then
              return corners
            end

            local function openCornerFile(path)
              return io.open(path, "r")
            end

            local safeTrackId = trackId:gsub("[\\\\/:]", "_")
            local f = openCornerFile("corners/" .. safeTrackId .. ".csv")
            if not f then
              -- Try unsanitized track id if the user has non-ASCII or unusual names
              f = openCornerFile("corners/" .. trackId .. ".csv")
            end
            if not f then
              return corners
            end

            local firstLine = true
            local cornerNum = 0
            for line in f:lines() do
              if firstLine then
                firstLine = false  -- Skip header
              elseif line ~= "" then
                local fields = parseCSVLine(line)
                if #fields >= 3 then
                  local startPos = tonumber(fields[2])
                  local endPos = tonumber(fields[3])

                  if startPos and endPos then
                    cornerNum = cornerNum + 1
                    table.insert(corners, {
                      number = cornerNum,
                      name = fields[1] ~= "" and fields[1] or ("Corner " .. cornerNum),
                      startPos = startPos,
                      endPos = endPos
                    })
                  end
                end
              end
            end
            f:close()
            return corners
          end

          _web_track_corners = loadCornersForTrack(_web_selected_lap and _web_selected_lap.track or nil)

          -- Compute brake scale from loaded laps
          local maxBrake = 90
          if _web_selected_lap then
            maxBrake = math.max(maxBrake, _web_selected_lap:maxBrakeBars() or 0)
          end
          if _web_ref_lap then
            maxBrake = math.max(maxBrake, _web_ref_lap:maxBrakeBars() or 0)
          end
          _web_brake_scale = math.ceil(maxBrake * 1.11 / 10) * 10
          _web_brake_scale = math.max(90, _web_brake_scale)
        `);

        lapsLoadedRef.current = key;
        console.log("[TelemetryCanvas] Laps loaded for", lapPath);
      } catch (err) {
        console.error("[TelemetryCanvas] Error loading laps:", err);
      }
    })();
  }, [lapPath, referencePath]);

  // Main render loop
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    setCanvas(canvas);

    let running = true;
    let lastTime = performance.now();

    const render = async () => {
      if (!running) return;

      const now = performance.now();
      const dt = (now - lastTime) / 1000;
      lastTime = now;

      const ctx = canvas.getContext("2d");
      if (!ctx) return;

      // Clear canvas
      const dpr = window.devicePixelRatio || 1;
      ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);

      // Update window size in UI context
      uiContext.windowSize = {
        x: canvas.width / dpr,
        y: canvas.height / dpr,
      };
      uiContext.beginFrameForCanvasRender();
      uiContext._lastItemHovered = false;
      uiContext._lastHoveredRect = null;

      // Reset layout state (but NOT single-frame input like clicks/wheel - those
      // need to survive until the draw consumes them)
      uiContext.cursor = { x: 0, y: 0 };
      resetBridgeCalls();

      try {
        // Draw background
        ctx.fillStyle = "#0f0f1a";
        ctx.fillRect(0, 0, canvas.width / dpr, canvas.height / dpr);

        // Call real lap_telemetry.draw() with context built from loaded laps
        const drawStart = performance.now();
        await doString(`
          local lt = require('lib.windows.lap_telemetry')
          local ca = require('lib.windows.corner_analysis')
          local showCornerAnalysis = ${showCornerAnalysis ? "true" : "false"}
          if _web_selected_lap then
            local context = {
              history = { _web_selected_lap },
              historyReferences = {},
              bestInSession = _web_selected_lap,
              bestLap = _web_ref_lap,
              trackCorners = _web_track_corners or {},
              brakeScaleBar = _web_brake_scale or 100,
            }
            local shouldShowCornerAnalysis = showCornerAnalysis
            if shouldShowCornerAnalysis then
              local ok, err = pcall(function()
                ca.draw(${dt}, _web_selected_lap, _web_ref_lap, _web_track_corners or {})
              end)
              if not ok then
                ac.log("corner_analysis draw failed: " .. tostring(err))
              end
            else
              lt.draw(${dt}, context)
            end
          else
            ui.setCursor(vec2(10, 10))
            ui.pushStyleColor(ui.StyleColor.Text, rgbm(1, 0.5, 0.5, 1))
            ui.text("Failed to load lap data")
            ui.popStyleColor()
          end
        `);
        const drawMs = performance.now() - drawStart;

        // Track perf
        perf.frameCount++;
        perf.totalDrawMs += drawMs;
        perf.minDrawMs = Math.min(perf.minDrawMs, drawMs);
        perf.maxDrawMs = Math.max(perf.maxDrawMs, drawMs);
        perf.drawCalls += getBridgeCalls();
        reportPerf();
        } catch (err) {
          console.error("[Render] Error:", err);
          ctx.fillStyle = "#f44";
          ctx.font = "14px monospace";
          ctx.fillText(`Error: ${err}`, 10, 30);
        } finally {
          uiContext.drawTooltip();

      }

      // Clear single-frame input state AFTER draw consumed it
      uiContext._mouseClicked = [false, false, false];
      uiContext._mouseReleased = [false, false, false];
      uiContext._wheelDelta = 0;
      uiContext._wheelDeltaH = 0;

      frameRef.current = requestAnimationFrame(render);
    };

    render();

    return () => {
      running = false;
      if (frameRef.current) {
        cancelAnimationFrame(frameRef.current);
      }
    };
  }, [lapPath, referencePath, showCornerAnalysis]);

  // Mouse event handlers
  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    uiContext.handleMouseMove(e.nativeEvent);
  }, []);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    uiContext.handleMouseDown(e.nativeEvent);
  }, []);

  const handleMouseUp = useCallback((e: React.MouseEvent) => {
    uiContext.handleMouseUp(e.nativeEvent);
  }, []);

  // Use native wheel listener to prevent page scroll (React's onWheel is passive)
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const handleWheel = (e: WheelEvent) => {
      e.preventDefault();
      uiContext.handleWheel(e);
    };
    canvas.addEventListener("wheel", handleWheel, { passive: false });
    return () => canvas.removeEventListener("wheel", handleWheel);
  }, []);

  return (
    <div ref={containerRef} style={{ width: "100%", height: "100%" }}>
      <canvas
        ref={canvasRef}
        onMouseMove={handleMouseMove}
        onMouseDown={handleMouseDown}
        onMouseUp={handleMouseUp}
        style={{ display: "block" }}
      />
    </div>
  );
}
