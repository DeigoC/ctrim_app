// Firebase Cloud Messaging Service Worker for Web Push Notifications
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCqZuLrFFe8IB3s-eNt_wNhev__jw9-sj8',
  authDomain: 'ctrim-8b49b.firebaseapp.com',
  projectId: 'ctrim-8b49b',
  storageBucket: 'ctrim-8b49b.appspot.com',
  messagingSenderId: '92089281469',
  appId: '1:92089281469:web:4b511a3216878d527680d4',
  measurementId: 'G-12R3WV90ZL',
});

const messaging = firebase.messaging();

function buildNotificationOptions(payload) {
  const appData = payload.data || {};
  return {
    body: payload.notification?.body || appData.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: appData,
    tag: appData.PostID || appData.InfoPage || 'ctrim-notification',
    requireInteraction: false,
    vibrate: [200, 100, 200],
  };
}

messaging.onBackgroundMessage((payload) => {
  console.log('[NOTIF] SW onBackgroundMessage', payload);

  const notificationTitle = payload.notification?.title || payload.data?.title || 'CTRIM App Notification';
  const notificationOptions = buildNotificationOptions(payload);

  return self.registration.showNotification(notificationTitle, notificationOptions)
    .then(() => console.log('[NOTIF] SW showNotification OK:', notificationTitle))
    .catch((err) => console.error('[NOTIF] SW showNotification FAILED:', err, notificationOptions));
});

self.addEventListener('notificationclick', (event) => {
  console.log('[NOTIF] SW notificationclick', event);

  event.notification.close();

  const data = event.notification.data;
  let urlToOpen = '/';

  if (data?.PostID) {
    urlToOpen = `/?postId=${data.PostID}`;
  } else if (data?.InfoPage) {
    urlToOpen = `/?infoPage=${data.InfoPage}`;
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.registration.scope) && 'focus' in client) {
          client.postMessage({
            type: 'NOTIFICATION_CLICKED',
            data: data,
          });
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    }),
  );
});
