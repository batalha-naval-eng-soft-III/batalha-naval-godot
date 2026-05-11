export type GodotWebBridge = {
  auth: {
    signInWithGoogle(): void;
    getRedirectResult(): Promise<string | null>;
    signOut(): Promise<void>;
  };
  firestore: {
    getDocument(path: string): Promise<string | null>;
    getCollection(path: string): Promise<string>;

    listenToDocument(subscriptionId: string, path: string, onData: unknown, onError?: unknown): void;

    listenToCollection(subscriptionId: string, path: string, onData: unknown, onError?: unknown): void;

    unsubscribe(subscriptionId: string): void;
    unsubscribeAll(): void;
  };
};

declare global {
  interface Window {
    GodotWebBridge: GodotWebBridge;
  }
}
