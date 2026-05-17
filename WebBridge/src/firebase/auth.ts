import {
  getAuth,
  GoogleAuthProvider,
  signInWithRedirect,
  getRedirectResult,
  signOut as firebaseSignOut,
} from "firebase/auth";

import { firebaseApp } from "./app";

export const auth = getAuth(firebaseApp);
const googleProvider = new GoogleAuthProvider();

export function signInWithGoogle() {
  return signInWithRedirect(auth, googleProvider);
}

export async function readRedirectResult() {
  const result = await getRedirectResult(auth);

  if (!result?.user) {
    return null;
  }

  return JSON.stringify({
    uid: result.user.uid,
    email: result.user.email,
    displayName: result.user.displayName,
    photoURL: result.user.photoURL,
  });
}

export function signOut() {
  return firebaseSignOut(auth);
}
