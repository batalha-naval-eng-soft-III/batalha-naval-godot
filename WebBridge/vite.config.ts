import { defineConfig } from "vite";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const currentDir = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  build: {
    outDir: "../web-build/assets",
    emptyOutDir: false,
    lib: {
      entry: resolve(currentDir, "src/index.ts"),
      name: "GodotWebBridge",
      formats: ["iife"],
      fileName: () => "godot-web-bridge.js",
    },
  },
});
