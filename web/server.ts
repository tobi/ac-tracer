import index from "./index.html";

const LUA_DIR = "..";

Bun.serve({
  port: 3000,
  routes: {
    "/": index,
    // Serve Lua files from ../lib
    "/lua/*": async (req) => {
      const url = new URL(req.url);
      const path = url.pathname.replace("/lua/", "");
      const file = Bun.file(`${LUA_DIR}/${path}`);
      if (await file.exists()) {
        return new Response(file, {
          headers: { "Content-Type": "text/plain" },
        });
      }
      return new Response("Not found", { status: 404 });
    },
    // List available track CSVs
    "/api/tracks": async () => {
      const dir = `${LUA_DIR}/tracks`;
      const glob = new Bun.Glob("*.csv");
      const files: string[] = [];
      for await (const path of glob.scan(dir)) {
        files.push(path);
      }
      files.sort();
      return Response.json(files);
    },
    // Serve track CSV files
    "/tracks/*": async (req) => {
      const url = new URL(req.url);
      const path = url.pathname.replace("/tracks/", "");
      const file = Bun.file(`${LUA_DIR}/tracks/${path}`);
      if (await file.exists()) {
        return new Response(file, {
          headers: { "Content-Type": "text/csv" },
        });
      }
      return new Response("Not found", { status: 404 });
    },
    // Serve corner definition CSVs
    "/corners/*": async (req) => {
      const url = new URL(req.url);
      const path = decodeURIComponent(url.pathname.replace("/corners/", ""));
      const file = Bun.file(`${LUA_DIR}/corners/${path}`);
      if (await file.exists()) {
        return new Response(file, {
          headers: { "Content-Type": "text/csv" },
        });
      }
      return new Response("Not found", { status: 404 });
    },
  },
  development: {
    hmr: true,
    console: true,
  },
});

console.log("AC Tracer Web running at http://localhost:3000");
