// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.11.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.11.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAteDHCR0gPbkxIPQyql0UfAwTDZ518fKI",
  authDomain: "health-apps-16496.firebaseapp.com",
  projectId: "health-apps-16496",
  storageBucket: "health-apps-16496.appspot.com",
  messagingSenderId: "938119019838",
  appId: "1:938119019838:web:9ac6f253c41dd727265406f"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);
  const { title, body } = payload.notification;
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png'
  });
});
