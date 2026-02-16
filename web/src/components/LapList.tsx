import React from "react";

interface LapInfo {
  id: string;
  filename: string;
  track: string;
  car: string;
  time: number;
  samples: number;
}

interface LapListProps {
  laps: LapInfo[];
  selectedId: string | null;
  referenceId: string | null;
  onSelect: (id: string) => void;
  onSetReference: (id: string | null) => void;
  formatTime: (ms: number) => string;
}

export default function LapList({
  laps,
  selectedId,
  referenceId,
  onSelect,
  onSetReference,
  formatTime,
}: LapListProps) {
  if (laps.length === 0) {
    return (
      <div className="lap-list">
        <p style={{ color: "#666", fontSize: "0.875rem", padding: "0.5rem" }}>
          No laps loaded
        </p>
      </div>
    );
  }

  return (
    <div className="lap-list">
      {laps.map((lap) => (
        <div
          key={lap.id}
          className={`lap-item ${lap.id === selectedId ? "selected" : ""}`}
          onClick={() => onSelect(lap.id)}
          onContextMenu={(e) => {
            e.preventDefault();
            // Right-click sets as reference
            onSetReference(lap.id === referenceId ? null : lap.id);
          }}
        >
          <div className="lap-name">
            {lap.filename}
            {lap.id === referenceId && (
              <span
                style={{
                  marginLeft: "0.5rem",
                  fontSize: "0.75rem",
                  color: "#0f4c75",
                  fontWeight: "bold",
                }}
              >
                REF
              </span>
            )}
          </div>
          <div className="lap-time">
            {formatTime(lap.time)} • {lap.samples} samples
          </div>
          <div
            style={{ fontSize: "0.75rem", color: "#555", marginTop: "0.25rem" }}
          >
            {lap.track} / {lap.car}
          </div>
        </div>
      ))}
      <p
        style={{
          fontSize: "0.7rem",
          color: "#444",
          marginTop: "0.5rem",
          padding: "0.25rem",
        }}
      >
        Right-click lap to set as reference
      </p>
    </div>
  );
}
