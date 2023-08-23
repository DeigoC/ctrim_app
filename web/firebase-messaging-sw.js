importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: 'AIzaSyCqZuLrFFe8IB3s-eNt_wNhev__jw9-sj8',
    appId: '1:92089281469:web:4b511a3216878d527680d4',
    messagingSenderId: '92089281469',
    projectId: 'ctrim-8b49b',
    authDomain: 'ctrim-8b49b.firebaseapp.com',
    storageBucket: 'ctrim-8b49b.appspot.com',
    measurementId: 'G-12R3WV90ZL',
});
// Necessary to receive background messages:
const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
    console.log("onBackgroundMessage", m);
});