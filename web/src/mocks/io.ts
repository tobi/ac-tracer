// Virtual filesystem mock for io.* API
// Supports reading files loaded via drag-drop or fetch

class VFSHandle {
  private content: string;
  private cursor: number = 0;

  constructor(content: string) {
    this.content = content;
  }

  read(mode?: string | number): string | null {
    if (mode === "*a" || mode === undefined) {
      // Read all
      const result = this.content.substring(this.cursor);
      this.cursor = this.content.length;
      return result;
    }
    if (mode === "*l") {
      // Read line
      if (this.cursor >= this.content.length) return null;
      const newlinePos = this.content.indexOf("\n", this.cursor);
      let line: string;
      if (newlinePos === -1) {
        line = this.content.substring(this.cursor);
        this.cursor = this.content.length;
      } else {
        line = this.content.substring(this.cursor, newlinePos);
        this.cursor = newlinePos + 1;
      }
      // Remove trailing \r if present
      if (line.endsWith("\r")) {
        line = line.slice(0, -1);
      }
      return line;
    }
    if (typeof mode === "number") {
      // Read N bytes
      const result = this.content.substring(this.cursor, this.cursor + mode);
      this.cursor += mode;
      return result || null;
    }
    return null;
  }

  lines(): () => string | null {
    return () => this.read("*l");
  }

  write(_data: string): boolean {
    // Read-only for now
    return false;
  }

  seek(whence?: string, offset?: number): number {
    offset = offset || 0;
    if (whence === "set") {
      this.cursor = offset;
    } else if (whence === "cur") {
      this.cursor += offset;
    } else if (whence === "end") {
      this.cursor = this.content.length + offset;
    }
    this.cursor = Math.max(0, Math.min(this.content.length, this.cursor));
    return this.cursor;
  }

  close(): boolean {
    return true;
  }
}

class VFSWriteHandle {
  private buffer: string = "";
  private path: string;
  private vfs: VirtualFS;

  constructor(path: string, vfs: VirtualFS) {
    this.path = path;
    this.vfs = vfs;
  }

  read(): null {
    return null;
  }

  write(data: string): boolean {
    this.buffer += data;
    return true;
  }

  seek(): number {
    return this.buffer.length;
  }

  close(): boolean {
    this.vfs.addFile(this.path, this.buffer);
    return true;
  }
}

class VirtualFS {
  private files: Map<string, string> = new Map();
  private dirs: Set<string> = new Set([".", "tracks", "corners"]);

  private normalize(path: string): string {
    // Normalize path separators and remove trailing slashes
    let norm = path.replace(/\\/g, "/").replace(/\/+/g, "/");
    if (norm.length > 1 && norm.endsWith("/")) {
      norm = norm.slice(0, -1);
    }
    return norm;
  }

  addFile(path: string, content: string) {
    const norm = this.normalize(path);
    this.files.set(norm, content);

    // Ensure parent directories exist
    const parts = norm.split("/");
    for (let i = 1; i < parts.length; i++) {
      this.dirs.add(parts.slice(0, i).join("/"));
    }
  }

  getFile(path: string): string | undefined {
    return this.files.get(this.normalize(path));
  }

  removeFile(path: string): boolean {
    return this.files.delete(this.normalize(path));
  }

  listFiles(): string[] {
    return Array.from(this.files.keys());
  }

  // io.open(path, mode) -> handle or nil
  open(path: string, mode: string = "r"): VFSHandle | VFSWriteHandle | null {
    const norm = this.normalize(path);
    const isWrite = mode.includes("w") || mode.includes("a") || mode.includes("+");

    if (isWrite) {
      const initial = mode.includes("a") ? this.files.get(norm) || "" : "";
      const handle = new VFSWriteHandle(norm, this);
      if (initial) {
        handle.write(initial);
      }
      return handle;
    }

    // Read mode
    const content = this.files.get(norm);
    if (content === undefined) {
      return null;
    }
    return new VFSHandle(content);
  }

  // io.exists(path) -> boolean (CSP calls this io.fileExists)
  exists(path: string): boolean {
    return this.files.has(this.normalize(path));
  }

  // io.fileExists(path) -> boolean
  fileExists(path: string): boolean {
    return this.exists(path);
  }

  // io.dirExists(path) -> boolean
  dirExists(path: string): boolean {
    return this.dirs.has(this.normalize(path));
  }

  // io.fileSize(path) -> number
  fileSize(path: string): number {
    const content = this.files.get(this.normalize(path));
    return content !== undefined ? content.length : -1;
  }

  // io.createDir(path) -> boolean
  createDir(path: string): boolean {
    const norm = this.normalize(path);
    if (!this.dirs.has(norm)) {
      this.dirs.add(norm);
    }
    return true;
  }

  // io.scanDir(path, pattern?) -> string[] | nil
  scanDir(path: string, pattern?: string): string[] | null {
    const norm = this.normalize(path);
    if (!this.dirs.has(norm) && norm !== "") {
      return null;
    }

    const prefix = norm === "" || norm === "." ? "" : norm + "/";
    const results: string[] = [];

    // Parse pattern (e.g., "*.csv")
    let suffix: string | null = null;
    if (pattern && pattern.startsWith("*.")) {
      suffix = pattern.substring(1).toLowerCase();
    }

    for (const filePath of this.files.keys()) {
      if (filePath.startsWith(prefix)) {
        const rest = filePath.substring(prefix.length);
        // Only include direct children (no subdirectories)
        if (!rest.includes("/")) {
          if (!suffix || rest.toLowerCase().endsWith(suffix)) {
            results.push(rest);
          }
        }
      }
    }

    return results.length > 0 ? results : null;
  }
}

// Create singleton VFS instance
export const vfs = new VirtualFS();

// Export the io namespace object for Lua
export const io = {
  open: (path: string, mode?: string) => vfs.open(path, mode || "r"),
  exists: (path: string) => vfs.exists(path),
  fileExists: (path: string) => vfs.fileExists(path),
  dirExists: (path: string) => vfs.dirExists(path),
  fileSize: (path: string) => vfs.fileSize(path),
  createDir: (path: string) => vfs.createDir(path),
  scanDir: (path: string, pattern?: string) => vfs.scanDir(path, pattern),

  // Allow adding files from JS side (for drag-drop)
  _vfs: vfs,
};

export default io;
