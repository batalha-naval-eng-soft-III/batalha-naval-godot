import { mkdir } from "node:fs/promises";
import { spawnSync, spawn } from "node:child_process";
import path from "node:path";

const root = process.cwd();
const webBuildDir = path.join(root, "web-build");

const shouldServe = process.argv.includes("--serve");

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    stdio: "inherit",
    shell: process.platform === "win32",
    ...options,
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

await mkdir(path.join(webBuildDir, "assets"), {
  recursive: true,
});

console.log("Exporting Godot web build...");
run("godot", ["--headless", "--export-release", "Web", path.join("web-build", "index.html")]);

console.log("Building TypeScript bridge...");
run("bun", ["--cwd", "WebBridge", "run", "build"]);

if (shouldServe) {
  console.log("Serving web-build...");

  spawn("bun", ["x", "serve", "web-build"], {
    stdio: "inherit",
    shell: process.platform === "win32",
  });
}
