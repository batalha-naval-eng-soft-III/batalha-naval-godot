import { initializeApp } from "firebase/app";

const firebaseConfig = {
  apiKey: "AIzaSyDElepKQDGyA4",
  authDomain: "battleship-multiplayer-cc51c.firebaseapp.com",
  projectId: "battleship-multiplayer-cc51c",
  // TODO: obter configuração
  appId: "..",
};

export const firebaseApp = initializeApp(firebaseConfig);
