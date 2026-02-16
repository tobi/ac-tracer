import React, { useState, useEffect, useCallback, useRef, useMemo } from "react";
import {
  initLua,
  loadLuaFiles,
  doString,
  vfs,
  drainLuaEvents,
} from "./lua/engine";
import FileDrop from "./components/FileDrop";
import LapList from "./components/LapList";
import TelemetryCanvas from "./components/TelemetryCanvas";

// Lap info extracted from Lua
interface LapInfo {
  id: string;
  filename: string;
  track: string;
  car: string;
  time: number;
  samples: number;
}

type ToolId = "telemetry" | "cornerAnalysis" | "browser";

interface ToolWindowState {
  open: boolean;
  x: number;
  y: number;
  w: number;
  h: number;
  z: number;
}

type DragState = {
  id: ToolId;
  startMouseX: number;
  startMouseY: number;
  startWindowX: number;
  startWindowY: number;
};

const BASE_WINDOWS: Record<ToolId, ToolWindowState> = {
  browser: {
    open: true,
    x: 16,
    y: 72,
    w: 360,
    h: 620,
    z: 10,
  },
  telemetry: {
    open: true,
    x: 392,
    y: 72,
    w: 980,
    h: 620,
    z: 20,
  },
  cornerAnalysis: {
    open: false,
    x: 128,
    y: 96,
    w: 980,
    h: 620,
    z: 30,
  },
};

export default function App() {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [laps, setLaps] = useState<LapInfo[]>([]);
  const [selectedLapId, setSelectedLapId] = useState<string | null>(null);
  const [referenceLapId, setReferenceLapId] = useState<string | null>(null);
  const [serverTracks, setServerTracks] = useState<string[]>([]);
  const [loadingTrack, setLoadingTrack] = useState<string | null>(null);
  const [toolWindows, setToolWindows] = useState<Record<ToolId, ToolWindowState>>(
    BASE_WINDOWS
  );
  const loadedCornerTracks = useRef<Set<string>>(new Set());
  const nextZ = useRef(100);
  const dragState = useRef<DragState | null>(null);

  const loadedLapCount = useRef(0);
  const eventPumpFrame = useRef<number>(0);

  const sanitizeTrackId = useCallback((trackId: string) => {
    return trackId.replace(/[\\/:]/g, "_");
  }, []);

  const bringWindowToFront = useCallback((id: ToolId) => {
    setToolWindows((prev) => {
      nextZ.current += 1;
      return {
        ...prev,
        [id]: { ...prev[id], z: nextZ.current },
      };
    });
  }, []);

  const setWindowOpen = useCallback((id: ToolId, open: boolean) => {
    setToolWindows((prev) => ({
      ...prev,
      [id]: { ...prev[id], open },
    }));

    if (!open && id === "cornerAnalysis") {
      void doString(`
        local ca = require('lib.windows.corner_analysis')
        if ca and ca.clearFrozenCorner then
          ca.clearFrozenCorner()
        end
      `);
    }
  }, []);

  const toggleWindow = useCallback(
    (id: ToolId) => {
      setToolWindows((prev) => {
        const nextOpen = !prev[id].open;
        if (!nextOpen && id === "cornerAnalysis") {
          void doString(`
            local ca = require('lib.windows.corner_analysis')
            if ca and ca.clearFrozenCorner then
              ca.clearFrozenCorner()
            end
          `);
        }
        return {
          ...prev,
          [id]: { ...prev[id], open: nextOpen, z: nextZ.current + 1 },
        };
      });
      nextZ.current += 1;
      bringWindowToFront(id);
    },
    [bringWindowToFront]
  );

  const loadCornerCSV = useCallback(
    async (trackId: string | null | undefined) => {
      if (!trackId) return;
      const filename = `${sanitizeTrackId(trackId)}.csv`;
      if (loadedCornerTracks.current.has(filename)) return;

      try {
        const cornerRes = await fetch(`/corners/${encodeURIComponent(filename)}`);
        if (!cornerRes.ok) return;

        const cornerContent = await cornerRes.text();
        vfs.addFile(`corners/${filename}`, cornerContent);
        loadedCornerTracks.current.add(filename);
        console.log(`[App] Loaded corners: ${filename}`);
      } catch (err) {
        console.debug(`[App] No corners file for ${filename}:`, err);
      }
    },
    [sanitizeTrackId]
  );

  // Initialize Lua engine on mount
  useEffect(() => {
    async function init() {
      try {
        setIsLoading(true);
        setError(null);

        // Initialize Lua and load source files
        await initLua();
        await loadLuaFiles();

        // Test that lap module loads
        await doString(`
          local lap = require('lib.lap')
          print('Lap module loaded, SAMPLE_RATE=' .. tostring(lap.SAMPLE_RATE))
        `);

        console.log("[App] Lua engine ready");
        setIsLoading(false);

        // Fetch list of available server tracks
        try {
          const res = await fetch("/api/tracks");
          if (res.ok) {
            const files: string[] = await res.json();
            setServerTracks(files);
          }
        } catch {}
      } catch (err) {
        console.error("[App] Init error:", err);
        setError(String(err));
        setIsLoading(false);
      }
    }
    init();
  }, []);

  const parseLapFromCSV = useCallback(
    async (path: string, filename: string) => {
      const result = await doString(`
        local lap = require('lib.lap')
        local lapData = lap.fromCSV('${path}')
        if lapData then
          return {
            track = lapData.track or 'unknown',
            car = lapData.car or 'unknown',
            time = lapData.time or 0,
            samples = lapData:length() or 0,
            valid = lapData.valid or false,
          }
        end
        return nil
      `);

      if (!result) return null;
      const info = result as { track: string; car: string; time: number; samples: number };
      await loadCornerCSV(info.track);

      const lapInfo: LapInfo = {
        id: path,
        filename,
        track: info.track,
        car: info.car,
        time: info.time,
        samples: info.samples,
      };

      setLaps((prev) => {
        if (prev.find((l) => l.id === path)) return prev;
        loadedLapCount.current += 1;
        return [...prev, lapInfo];
      });

      return lapInfo;
    },
    [loadCornerCSV]
  );

  // Load a server track CSV on demand
  const loadServerTrack = useCallback(
    async (filename: string) => {
      const path = `tracks/${filename}`;

      // Already loaded?
      if (laps.find((l) => l.id === path)) {
        setSelectedLapId(path);
        return;
      }

      setLoadingTrack(filename);
      try {
        const csvRes = await fetch(`/tracks/${filename}`);
        if (!csvRes.ok) throw new Error(`Failed to fetch ${filename}`);
        const content = await csvRes.text();

        vfs.addFile(path, content);

        const parsed = await parseLapFromCSV(path, filename);
        if (parsed) {
          setSelectedLapId(path);
          console.log(`[App] Loaded server track: ${filename} - ${formatTime(parsed.time)}`);
        }
      } catch (err) {
        console.error(`[App] Error loading ${filename}:`, err);
      } finally {
        setLoadingTrack(null);
      }
    },
    [laps, parseLapFromCSV]
  );

  // Handle CSV file drop
  const handleFileDrop = useCallback(
    async (files: File[]) => {
      for (const file of files) {
        try {
          const content = await file.text();
          const filename = file.name;
          const path = `tracks/${filename}`;

          // Add to VFS
          vfs.addFile(path, content);
          console.log(`[App] Added file: ${path} (${content.length} bytes)`);

          // Parse CSV via Lua
          const parsed = await parseLapFromCSV(path, filename);
          if (parsed) {
            setSelectedLapId((prev) => prev ?? path);
            console.log(`[App] Loaded lap: ${filename} - ${formatTime(parsed.time)}`);
            if (!toolWindows.browser.open) {
              setWindowOpen("browser", true);
            }
          } else {
            console.warn(`[App] Failed to parse: ${filename}`);
          }
        } catch (err) {
          console.error(`[App] Error loading ${file.name}:`, err);
        }
      }
    },
    [parseLapFromCSV, toolWindows.browser.open, setWindowOpen]
  );

  const handleLuaEvent = useCallback(
    (event: { type: string; payload: unknown }) => {
      if (event.type === "corner_selected") {
        setWindowOpen("cornerAnalysis", true);
        bringWindowToFront("cornerAnalysis");
        return;
      }

      // Future UI responses for hover/other telemetry events can be added here
      // without changing the Lua-side bridge contract.
    },
    [setWindowOpen, bringWindowToFront]
  );

  // Drain Lua events in a single place so one window cannot steal events
  // from another when multiple canvases are active.
  useEffect(() => {
    let running = true;
    const pump = () => {
      if (!running) return;
      const events = drainLuaEvents();
      for (const event of events) {
        handleLuaEvent(event);
      }
      eventPumpFrame.current = requestAnimationFrame(pump);
    };

    eventPumpFrame.current = requestAnimationFrame(pump);
    return () => {
      running = false;
      cancelAnimationFrame(eventPumpFrame.current);
    };
  }, [handleLuaEvent]);

  const handleWindowDragStart = useCallback(
    (id: ToolId, e: React.MouseEvent) => {
      const target = e.target as HTMLElement;
      if (target.closest(".tool-close")) return;

      const current = toolWindows[id];
      if (!current?.open) return;

      dragState.current = {
        id,
        startMouseX: e.clientX,
        startMouseY: e.clientY,
        startWindowX: current.x,
        startWindowY: current.y,
      };
      bringWindowToFront(id);
    },
    [bringWindowToFront, toolWindows]
  );

  useEffect(() => {
    const onMouseMove = (e: MouseEvent) => {
      const drag = dragState.current;
      if (!drag) return;

      const dx = e.clientX - drag.startMouseX;
      const dy = e.clientY - drag.startMouseY;

      setToolWindows((prev) => {
        const current = prev[drag.id];
        if (!current) return prev;

        return {
          ...prev,
          [drag.id]: {
            ...current,
            x: Math.max(0, drag.startWindowX + dx),
            y: Math.max(0, drag.startWindowY + dy),
          },
        };
      });
    };

    const onMouseUp = () => {
      dragState.current = null;
    };

    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mouseup", onMouseUp);

    return () => {
      window.removeEventListener("mousemove", onMouseMove);
      window.removeEventListener("mouseup", onMouseUp);
    };
  }, []);

  // Format time in mm:ss.sss
  function formatTime(ms: number): string {
    if (!ms || ms <= 0) return "--:--.---";
    const totalSec = ms / 1000;
    const min = Math.floor(totalSec / 60);
    const sec = totalSec % 60;
    return `${min}:${sec.toFixed(3).padStart(6, "0")}`;
  }

  const styleById = useMemo(
    () => ({
      browser: {
        left: `${toolWindows.browser.x}px`,
        top: `${toolWindows.browser.y}px`,
        width: `${toolWindows.browser.w}px`,
        height: `${toolWindows.browser.h}px`,
      },
      telemetry: {
        left: `${toolWindows.telemetry.x}px`,
        top: `${toolWindows.telemetry.y}px`,
        width: `${toolWindows.telemetry.w}px`,
        height: `${toolWindows.telemetry.h}px`,
      },
      cornerAnalysis: {
        left: `${toolWindows.cornerAnalysis.x}px`,
        top: `${toolWindows.cornerAnalysis.y}px`,
        width: `${toolWindows.cornerAnalysis.w}px`,
        height: `${toolWindows.cornerAnalysis.h}px`,
      },
    }),
    [toolWindows]
  );

  if (isLoading) {
    return (
      <div className="app">
        <div className="loading">
          <p>Initializing Lua engine...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="app">
        <div className="error">
          <h2>Error</h2>
          <p>{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="app">
      <header className="toolbar">
        <div className="toolbar-title">AC Tracer - Web Desktop</div>
        <div className="toolbar-tools">
          <button
            type="button"
            className={`tool-btn ${toolWindows.telemetry.open ? "tool-btn--active" : ""}`}
            onClick={() => toggleWindow("telemetry")}
          >
            Telemetry
          </button>
          <button
            type="button"
            className={`tool-btn ${toolWindows.cornerAnalysis.open ? "tool-btn--active" : ""}`}
            onClick={() => toggleWindow("cornerAnalysis")}
          >
            Corner Analysis
          </button>
          <button
            type="button"
            className={`tool-btn ${toolWindows.browser.open ? "tool-btn--active" : ""}`}
            onClick={() => toggleWindow("browser")}
          >
            Lap Browser
          </button>
        </div>
      </header>

      <main className="desktop">
        {toolWindows.browser.open && (
          <section
            className="tool-window"
            style={{ ...styleById.browser, zIndex: toolWindows.browser.z }}
            onMouseDown={() => bringWindowToFront("browser")}
          >
            <header
              className="tool-titlebar"
              onMouseDown={(event) => handleWindowDragStart("browser", event)}
            >
              <span className="tool-title">Lap Browser</span>
              <button
                type="button"
                className="tool-close"
                onClick={(event) => {
                  event.stopPropagation();
                  setWindowOpen("browser", false);
                }}
              >
                ×
              </button>
            </header>

            <div className="tool-content">
              <FileDrop onDrop={handleFileDrop} />

              {serverTracks.length > 0 && (
                <>
                  <div className="section-title">Server Tracks</div>
                  <div className="server-tracks">
                    {serverTracks.map((filename) => {
                      const isLoaded = laps.some((l) => l.id === `tracks/${filename}`);
                      const isLoadingThis = loadingTrack === filename;
                      return (
                        <button
                          key={filename}
                          className={`server-track-btn ${isLoaded ? "loaded" : ""}`}
                          onClick={() => loadServerTrack(filename)}
                          disabled={isLoadingThis}
                        >
                          <span className="track-name">{filename.replace(/\.csv$/i, "")}</span>
                          {isLoadingThis && <span className="track-status">loading...</span>}
                          {isLoaded && !isLoadingThis && <span className="track-status">loaded</span>}
                        </button>
                      );
                    })}
                  </div>
                </>
              )}

              <div className="section-title">Loaded Laps</div>
              <LapList
                laps={laps}
                selectedId={selectedLapId}
                referenceId={referenceLapId}
                onSelect={setSelectedLapId}
                onSetReference={setReferenceLapId}
                formatTime={formatTime}
              />
            </div>
          </section>
        )}

        {toolWindows.telemetry.open && (
          <section
            className="tool-window"
            style={{ ...styleById.telemetry, zIndex: toolWindows.telemetry.z }}
            onMouseDown={() => bringWindowToFront("telemetry")}
          >
            <header
              className="tool-titlebar"
              onMouseDown={(event) => handleWindowDragStart("telemetry", event)}
            >
              <span className="tool-title">Telemetry</span>
              <button
                type="button"
                className="tool-close"
                onClick={(event) => {
                  event.stopPropagation();
                  setWindowOpen("telemetry", false);
                }}
              >
                ×
              </button>
            </header>
            <div className="tool-content canvas-tool">
              {selectedLapId ? (
                <TelemetryCanvas
                  lapPath={selectedLapId}
                  referencePath={referenceLapId}
                  showCornerAnalysis={false}
                />
              ) : (
                <div className="loading">
                  <p>Drop a CSV file to view telemetry</p>
                </div>
              )}
            </div>
          </section>
        )}

        {toolWindows.cornerAnalysis.open && (
          <section
            className="tool-window"
            style={{ ...styleById.cornerAnalysis, zIndex: toolWindows.cornerAnalysis.z }}
            onMouseDown={() => bringWindowToFront("cornerAnalysis")}
          >
            <header
              className="tool-titlebar"
              onMouseDown={(event) => handleWindowDragStart("cornerAnalysis", event)}
            >
              <span className="tool-title">Corner Analysis</span>
              <button
                type="button"
                className="tool-close"
                onClick={(event) => {
                  event.stopPropagation();
                  setWindowOpen("cornerAnalysis", false);
                }}
              >
                ×
              </button>
            </header>
            <div className="tool-content canvas-tool">
              {selectedLapId ? (
                <TelemetryCanvas
                  lapPath={selectedLapId}
                  referencePath={referenceLapId}
                  showCornerAnalysis={true}
                />
              ) : (
                <div className="loading">
                  <p>Select a lap first</p>
                </div>
              )}
            </div>
          </section>
        )}
      </main>
    </div>
  );
}
