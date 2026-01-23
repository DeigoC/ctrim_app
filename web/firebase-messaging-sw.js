// Firebase Cloud Messaging Service Worker for Web Push Notifications
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyCqZuLrFFe8IB3s-eNt_wNhev__jw9-sj8',
  authDomain: 'ctrim-8b49b.firebaseapp.com',
  projectId: 'ctrim-8b49b',
  storageBucket: 'ctrim-8b49b.appspot.com',
  messagingSenderId: '92089281469',
  appId: '1:92089281469:web:4b511a3216878d527680d4',
  measurementId: 'G-12R3WV90ZL'
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Customize notification here
  const notificationTitle = payload.notification?.title || payload.data?.title || 'CTRIM App Notification';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: payload.data?.PostID || 'ctrim-notification',
    requireInteraction: false,
    vibrate: [200, 100, 200],
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.', event);
  
  event.notification.close();

  // Extract data from the notification
  const data = event.notification.data;
  let urlToOpen = '/';

  // If there's a PostID, construct the appropriate URL
  if (data && data.PostID) {
    urlToOpen = `/?postId=${data.PostID}`;
  } else if (data && data.InfoPage) {
    urlToOpen = `/?infoPage=${data.InfoPage}`;
  }

  // This looks to see if the current window is already open and focuses if it is
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Check if there's already a window open
      for (const client of clientList) {
        if (client.url.includes(self.registration.scope) && 'focus' in client) {
          // If we found an open window, post a message to it to handle the notification
          client.postMessage({
            type: 'NOTIFICATION_CLICKED',
            data: data
          });
          return client.focus();
        }
      }
      // If no window is open, open a new one
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
