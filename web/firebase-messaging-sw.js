importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAP3E8I1Fe8OoIThT9oPqvcEqXvC2321kc",
  authDomain: "bneeds-taxi-driver-5ecff.firebaseapp.com",
  projectId: "bneeds-taxi-driver-5ecff",
  storageBucket: "bneeds-taxi-driver-5ecff.firebasestorage.app",
  messagingSenderId: "1001711203204",
  appId: "1:1001711203204:web:633e2cf95a0e521bb923d1",
  measurementId: "G-4S98QTVM4Y"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
