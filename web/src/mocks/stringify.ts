// Stringify module matching CSP's API
// Provides Lua table serialization/deserialization

type LuaValue = null | boolean | number | string | LuaTable;
type LuaTable = { [key: string | number]: LuaValue };

function serializeValue(v: LuaValue, seen: Set<object>): string {
  if (v === null || v === undefined) {
    return "nil";
  }
  if (typeof v === "boolean") {
    return v ? "true" : "false";
  }
  if (typeof v === "number") {
    if (Number.isNaN(v)) return "0/0";
    if (!Number.isFinite(v)) return v > 0 ? "1/0" : "-1/0";
    return String(v);
  }
  if (typeof v === "string") {
    // Escape special characters for Lua string
    const escaped = v
      .replace(/\\/g, "\\\\")
      .replace(/"/g, '\\"')
      .replace(/\n/g, "\\n")
      .replace(/\r/g, "\\r")
      .replace(/\t/g, "\\t");
    return `"${escaped}"`;
  }
  if (typeof v === "object") {
    if (seen.has(v)) return "nil"; // Avoid circular refs
    seen.add(v);

    const parts: string[] = [];
    const keys = Object.keys(v);

    // Check if it's an array (sequential integer keys starting at 1)
    const isArray = keys.every((k, i) => String(i + 1) === k);

    if (isArray && keys.length > 0) {
      // Array-like table
      for (let i = 1; i <= keys.length; i++) {
        parts.push(serializeValue((v as LuaTable)[i], seen));
      }
    } else {
      // Dictionary-like table
      for (const k of keys) {
        const val = (v as LuaTable)[k];
        let keyStr: string;
        if (/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(k)) {
          keyStr = k;
        } else if (!isNaN(Number(k))) {
          keyStr = `[${k}]`;
        } else {
          keyStr = `[${serializeValue(k, seen)}]`;
        }
        parts.push(`${keyStr}=${serializeValue(val, seen)}`);
      }
    }
    return `{${parts.join(",")}}`;
  }
  return "nil";
}

function parseLuaTable(str: string): LuaValue {
  // Simple Lua table parser - handles basic cases
  // For safety, we use JSON.parse for simple values and handle tables specially
  const trimmed = str.trim();

  if (trimmed === "nil") return null;
  if (trimmed === "true") return true;
  if (trimmed === "false") return false;
  if (trimmed === "0/0") return NaN;
  if (trimmed === "1/0") return Infinity;
  if (trimmed === "-1/0") return -Infinity;

  // Number
  if (/^-?\d+\.?\d*$/.test(trimmed)) {
    return Number(trimmed);
  }

  // String
  if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
    return trimmed
      .slice(1, -1)
      .replace(/\\n/g, "\n")
      .replace(/\\r/g, "\r")
      .replace(/\\t/g, "\t")
      .replace(/\\"/g, '"')
      .replace(/\\\\/g, "\\");
  }

  // Table - use eval for simplicity (only for trusted data)
  if (trimmed.startsWith("{") && trimmed.endsWith("}")) {
    try {
      // Convert Lua table syntax to JS
      let js = trimmed
        .replace(/\[(\d+)\]=/g, "$1:") // [1]= -> 1:
        .replace(/(\w+)=/g, '"$1":') // key= -> "key":
        .replace(/nil/g, "null");
      return JSON.parse(js);
    } catch {
      return null;
    }
  }

  return null;
}

// Main stringify function (callable as stringify(data) or stringify.binary(data))
export function stringify(data: unknown): string {
  return serializeValue(data as LuaValue, new Set());
}

stringify.binary = (data: unknown): string => {
  return serializeValue(data as LuaValue, new Set());
};

stringify.parse = (str: string): LuaValue => {
  if (!str || str === "") return null;
  return parseLuaTable(str);
};

stringify.tryParse = <T>(str: string, defaultValue: T): LuaValue | T => {
  const result = stringify.parse(str);
  return result !== null ? result : defaultValue;
};

export default stringify;
