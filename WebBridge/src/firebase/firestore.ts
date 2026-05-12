import {
  collection,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  onSnapshot,
  type Unsubscribe,
} from 'firebase/firestore';

import { firebaseApp } from './app';

export const firestore = getFirestore(firebaseApp);

const subscriptions = new Map<string, Unsubscribe>();

function withFirestoreId<T extends Record<string, unknown>>(
  id: string,
  data: T,
): T & { id: string } {
  return {
    ...data,
    id,
  };
}

function stringify(payload: unknown): string {
  return JSON.stringify(payload);
}

export async function getDocument(path: string): Promise<string | null> {
  const ref = doc(firestore, path);
  const snapshot = await getDoc(ref);

  if (!snapshot.exists()) {
    return null;
  }

  return stringify(withFirestoreId(snapshot.id, snapshot.data()));
}

export async function getCollection(path: string): Promise<string> {
  const ref = collection(firestore, path);
  const snapshot = await getDocs(ref);

  const documents = snapshot.docs.map((document) =>
    withFirestoreId(document.id, document.data()),
  );

  return stringify(documents);
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
          stringify({
            exists: false,
            id: snapshot.id,
            data: null,
          }),
        );
        return;
      }

      onData(
        stringify({
          exists: true,
          id: snapshot.id,
          data: snapshot.data(),
        }),
      );
    },
    (error) => {
      subscriptions.delete(subscriptionId);
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
      const documents = snapshot.docs.map((document) =>
        withFirestoreId(document.id, document.data()),
      );

      onData(stringify(documents));
    },
    (error) => {
      subscriptions.delete(subscriptionId);
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
  for (const [subscriptionId, unsubscribeFn] of subscriptions) {
    unsubscribeFn();
    subscriptions.delete(subscriptionId);
  }
}
