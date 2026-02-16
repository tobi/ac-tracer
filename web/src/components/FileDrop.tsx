import React, { useState, useCallback, useRef } from "react";

interface FileDropProps {
  onDrop: (files: File[]) => void;
}

export default function FileDrop({ onDrop }: FileDropProps) {
  const [isDragging, setIsDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  }, []);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      e.stopPropagation();
      setIsDragging(false);

      const files = Array.from(e.dataTransfer.files).filter(
        (f) => f.name.endsWith(".csv") || f.name.endsWith(".CSV")
      );

      if (files.length > 0) {
        onDrop(files);
      }
    },
    [onDrop]
  );

  const handleClick = useCallback(() => {
    inputRef.current?.click();
  }, []);

  const handleFileChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = Array.from(e.target.files || []).filter(
        (f) => f.name.endsWith(".csv") || f.name.endsWith(".CSV")
      );

      if (files.length > 0) {
        onDrop(files);
      }

      // Reset input so same file can be selected again
      e.target.value = "";
    },
    [onDrop]
  );

  return (
    <div
      className={`drop-zone ${isDragging ? "dragging" : ""}`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      onClick={handleClick}
    >
      <input
        ref={inputRef}
        type="file"
        accept=".csv"
        multiple
        onChange={handleFileChange}
        style={{ display: "none" }}
      />
      <p>
        {isDragging
          ? "Drop CSV files here"
          : "Drop CSV files here or click to browse"}
      </p>
    </div>
  );
}
