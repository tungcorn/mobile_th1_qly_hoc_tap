// Service worker nhận thông báo FCM khi tab web ở chế độ nền.
// QUAN TRỌNG: điền firebaseConfig bên dưới bằng đúng giá trị của dự án Firebase
// (Project settings > General > Your apps > Web app), trùng với các --dart-define.
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'YOUR_FIREBASE_API_KEY',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  appId: 'YOUR_FIREBASE_APP_ID',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const n = payload.notification || {};
  const data = payload.data || {};
  self.registration.showNotification(n.title || data.title || 'Thông báo', {
    body: n.body || data.body || '',
    icon: '/icons/Icon-192.png',
    data: data,
  });
});
