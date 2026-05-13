import type { GodotWebBridge } from "./types";

export function registerBridge(bridge: GodotWebBridge) {
  window.GodotWebBridge = bridge;
}
