import { signInWithGoogle, readRedirectResult, signOut } from "../firebase/auth";

export const authBridge = {
  signInWithGoogle,
  getRedirectResult: readRedirectResult,
  signOut,
};
