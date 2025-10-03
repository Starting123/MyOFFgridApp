// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v9-compat and above, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDDYOTW5cNJjUd9LYuX9iUogtF7kEYzmjM",
  authDomain: "off-grid-sos-app.firebaseapp.com", 
  projectId: "off-grid-sos-app",
  storageBucket: "off-grid-sos-app.firebasestorage.app",
  messagingSenderId: "798849744293",
  appId: "1:798849744293:web:262d0a88bea3deddd6fc4c",
  measurementId: "G-MEASUREMENT_ID"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);