import {
  getDocument,
  getCollection,
  listenToDocument,
  listenToCollection,
  unsubscribe,
  unsubscribeAll,
} from "../firebase/firestore";
import type { GodotCallback } from "./types";

function callGodot(callback: GodotCallback | undefined, value: string): void {
  callback?.call(value);
}

export const firestoreBridge = {
  async getDocument(path: string): Promise<string | null> {
    return getDocument(path);
  },

  async getCollection(path: string): Promise<string> {
    return getCollection(path);
  },

  listenToDocument(subscriptionId: string, path: string, onData: GodotCallback, onError?: GodotCallback): void {
    listenToDocument(
      subscriptionId,
      path,
      (payload) => callGodot(onData, payload),
      (message) => callGodot(onError, message),
    );
  },

  listenToCollection(subscriptionId: string, path: string, onData: GodotCallback, onError?: GodotCallback): void {
    listenToCollection(
      subscriptionId,
      path,
      (payload) => callGodot(onData, payload),
      (message) => callGodot(onError, message),
    );
  },

  unsubscribe(subscriptionId: string): void {
    unsubscribe(subscriptionId);
  },

  unsubscribeAll(): void {
    unsubscribeAll();
  },
};
