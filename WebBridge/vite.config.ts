import { defineConfig } from "vite";
import { resolve } from "node:path";

export default defineConfig({
  build: {
    outDir: "../web-build/assets",
    emptyOutDir: false,
    lib: {
      entry: resolve(__dirname, "src/index.ts"),
      name: "GodotWebBridge",
      formats: ["iife"],
      fileName: () => "godot-web-bridge.js",
    },
  },
});
