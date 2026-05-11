import { getFirestore, doc, collection, getDoc, getDocs, onSnapshot, type Unsubscribe } from "firebase/firestore";

import { firebaseApp } from "./app";

export const firestore = getFirestore(firebaseApp);

const subscriptions = new Map<string, Unsubscribe>();

export async function getDocument(path: string): Promise<string | null> {
  const ref = doc(firestore, path);
  const snapshot = await getDoc(ref);

  if (!snapshot.exists()) {
    return null;
  }

  return JSON.stringify({
    id: snapshot.id,
    ...snapshot.data(),
  });
}

export async function getCollection(path: string): Promise<string> {
  const ref = collection(firestore, path);
  const snapshot = await getDocs(ref);

  const documents = snapshot.docs.map((document) => ({
    id: document.id,
    ...document.data(),
  }));

  return JSON.stringify(documents);
}

export function listenToDocument(
  subscriptionId: string,
  path: string,
  onData: (payload: string) => void,
  onError?: (message: string) => void,
): void {
  unsubscribe(subscriptionId);

  const ref = doc(firestore, path);

  const unsubscribeFn = onSnapshot(
    ref,
    (snapshot) => {
      if (!snapshot.exists()) {
        onData(
          JSON.stringify({
            exists: false,
            id: snapshot.id,
            data: null,
          }),
        );
        return;
      }

      onData(
        JSON.stringify({
          exists: true,
          id: snapshot.id,
          data: snapshot.data(),
        }),
      );
    },
    (error) => {
      onError?.(error.message);
    },
  );

  subscriptions.set(subscriptionId, unsubscribeFn);
}

export function listenToCollection(
  subscriptionId: string,
  path: string,
  onData: (payload: string) => void,
  onError?: (message: string) => void,
): void {
  unsubscribe(subscriptionId);

  const ref = collection(firestore, path);

  const unsubscribeFn = onSnapshot(
    ref,
    (snapshot) => {
      const documents = snapshot.docs.map((document) => ({
        id: document.id,
        ...document.data(),
      }));

      onData(JSON.stringify(documents));
    },
    (error) => {
      onError?.(error.message);
    },
  );

  subscriptions.set(subscriptionId, unsubscribeFn);
}

export function unsubscribe(subscriptionId: string): void {
  const unsubscribeFn = subscriptions.get(subscriptionId);

  if (!unsubscribeFn) {
    return;
  }

  unsubscribeFn();
  subscriptions.delete(subscriptionId);
}

export function unsubscribeAll(): void {
  for (const unsubscribeFn of subscriptions.values()) {
    unsubscribeFn();
  }

  subscriptions.clear();
}
