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

function hasNavigableTarget(data) {
  return !!(data && (data.PostID || data.InfoPage));
}

// FCM auto-displayed (notification+data) clicks wrap custom keys under FCM_MSG.
function extractAppData(notificationData) {
  if (!notificationData || typeof notificationData !== 'object') {
    return {};
  }
  if (hasNavigableTarget(notificationData)) {
    return notificationData;
  }
  const fcm = notificationData.FCM_MSG;
  if (fcm && typeof fcm === 'object') {
    if (fcm.data && typeof fcm.data === 'object' && hasNavigableTarget(fcm.data)) {
      return fcm.data;
    }
    if (hasNavigableTarget(fcm)) {
      return fcm;
    }
  }
  return notificationData;
}

function targetUrlFromData(data) {
  const origin = self.location.origin;
  if (data.PostID) {
    return `${origin}/?postId=${encodeURIComponent(data.PostID)}`;
  }
  if (data.InfoPage) {
    return `${origin}/?infoPage=${encodeURIComponent(data.InfoPage)}`;
  }
  return `${origin}/`;
}

// Must be registered BEFORE firebase.messaging(). FCM's own click handler
// stopImmediatePropagation()s and, with no fcmOptions.link, does nothing.
self.addEventListener('notificationclick', (event) => {
  console.log('[NOTIF] SW notificationclick', event);

  event.stopImmediatePropagation();
  event.notification.close();

  if (event.action === 'close') {
    return;
  }

  const data = extractAppData(event.notification.data);
  const urlToOpen = targetUrlFromData(data);

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
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

const messaging = firebase.messaging();

function buildNotificationOptions(payload) {
  const appData = payload.data || {};
  const options = {
    body: payload.notification?.body || appData.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: appData,
    tag: appData.PostID || appData.InfoPage || appData.TestNotif || 'ctrim-notification',
    requireInteraction: false,
    vibrate: [200, 100, 200],
  };

  if (appData.PostID) {
    options.actions = [
      { action: 'open', title: 'View post' },
      { action: 'close', title: 'Dismiss' },
    ];
  } else if (appData.InfoPage) {
    options.actions = [
      { action: 'open', title: 'View page' },
      { action: 'close', title: 'Dismiss' },
    ];
  }

  return options;
}

messaging.onBackgroundMessage((payload) => {
  console.log('[NOTIF] SW onBackgroundMessage', payload);

  // When the FCM payload includes a `notification` block, the browser already
  // displays it. Showing again here doubles the banner (common on iOS PWA / Safari).
  if (payload.notification?.title || payload.notification?.body) {
    console.log('[NOTIF] SW skip showNotification — browser handles notification payload');
    return;
  }

  const notificationTitle = payload.data?.title || 'CTRIM App Notification';
  const notificationOptions = buildNotificationOptions(payload);

  return self.registration.showNotification(notificationTitle, notificationOptions)
    .then(() => console.log('[NOTIF] SW showNotification OK:', notificationTitle))
    .catch((err) => console.error('[NOTIF] SW showNotification FAILED:', err, notificationOptions));
});
