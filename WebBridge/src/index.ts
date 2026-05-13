import { registerBridge } from "./bridge/register-bridge";
import { authBridge } from "./bridge/auth";
import { firestoreBridge } from "./bridge/firestore";

registerBridge({
  auth: authBridge,
  firestore: firestoreBridge,
});
