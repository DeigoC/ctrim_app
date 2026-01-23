# Web Push Notifications Setup Guide for CTRIM App

This guide explains the changes made to enable web push notifications and what you need to do to complete the setup.

## Files Modified

### 1. `/web/firebase-messaging-sw.js` (NEW)
- Created a Firebase Messaging Service Worker to handle background notifications on web
- Handles notification display when the app is not in focus
- Handles notification clicks and opens the appropriate page
- Configured with your Firebase web credentials

### 2. `/lib/firebase/messaging_manager.dart` (UPDATED)
- **IMPORTANT**: Added VAPID key placeholder - **YOU MUST UPDATE THIS**
- Enabled web support for requesting notification permissions
- Added proper error handling for all platforms
- Added token refresh listener
- Added documentation about topic limitations on web

### 3. `/web/index.html` (UPDATED)
- Added Firebase SDK scripts for web messaging
- Registered the Firebase Messaging Service Worker
- Service worker will now handle background notifications

### 4. `/lib/pages/home_page.dart` (UPDATED)
- Fixed platform-specific imports to work on web
- Updated notification image handling for web compatibility
- Added web notification listener setup

## Required Steps to Complete Setup

### Step 1: Get Your VAPID Key from Firebase

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ctrim-8b49b**
3. Click the gear icon (⚙️) and select **Project settings**
4. Navigate to the **Cloud Messaging** tab
5. Scroll down to **Web Push certificates**
6. If you don't have a key pair, click **Generate key pair**
7. Copy the **Key pair** value (it starts with something like "BNxxx...")

### Step 2: Update the VAPID Key

Open [/lib/firebase/messaging_manager.dart](lib/firebase/messaging_manager.dart) and replace:

```dart
static const String _vapidKey = 'YOUR_VAPID_KEY_HERE';
```

With your actual VAPID key:

```dart
static const String _vapidKey = 'BNxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
```

### Step 3: Test the Implementation

1. **Build and deploy your web app:**
   ```bash
   flutter build web --release
   ```

2. **Test notification permission request:**
   - Open your web app in a browser (preferably Chrome or Firefox)
   - The browser should prompt you to allow notifications
   - Check the browser console for any errors

3. **Test receiving notifications:**
   - Send a test notification from Firebase Console
   - Notifications should appear even when the app is in the background

## How It Works

### Foreground Notifications (App is Open)
- When the app is open, `FirebaseMessaging.onMessage` receives the notification
- The app shows a custom dialog with the notification content
- Users can click "Show More" to open the related content

### Background Notifications (App is Closed/Background)
- The service worker (`firebase-messaging-sw.js`) receives the notification
- Shows a browser notification with your app icon
- When clicked, opens or focuses your app and navigates to the relevant content

### Notification Data Structure
Your notifications should include these data fields:
- `PostID` - Opens a specific post when clicked
- `InfoPage` - Opens an information page when clicked
- `title` - Notification title
- `body` - Notification message

## Important Notes

### Web Platform Limitations

1. **Topic Subscriptions**: 
   - Topic subscriptions (`.subscribeToTopic()`) are **not supported on web**
   - Use device tokens instead for targeted notifications
   - Your server needs to maintain a list of web tokens and send to them individually

2. **Browser Support**:
   - Chrome, Firefox, Edge, and Safari (16+) support web push notifications
   - Users must grant permission for notifications
   - Some browsers may block notifications in incognito/private mode

3. **HTTPS Required**:
   - Web push notifications only work on HTTPS sites
   - Localhost is allowed for testing

4. **Service Worker Scope**:
   - The service worker must be at the root of your web app
   - It's already configured correctly in `/web/`

## Testing Checklist

- [ ] VAPID key has been added to `messaging_manager.dart`
- [ ] Web app builds without errors: `flutter build web`
- [ ] Browser prompts for notification permission
- [ ] Token is generated and logged in console
- [ ] Can receive foreground notifications (app open)
- [ ] Can receive background notifications (app closed)
- [ ] Notification clicks open the correct page
- [ ] No console errors related to messaging

## Troubleshooting

### No notification permission prompt
- Check browser settings - notifications might be blocked
- Ensure you're on HTTPS or localhost
- Check console for errors

### Notifications not appearing in background
- Verify service worker is registered (check Application tab in DevTools)
- Check if service worker is running (Application > Service Workers)
- Look for errors in the service worker console

### Token is null
- Ensure VAPID key is correct and matches your Firebase project
- Check if user granted permission
- Verify Firebase configuration in `firebase_options.dart`

### "Failed to register service worker"
- Ensure `firebase-messaging-sw.js` is in the `/web/` directory
- Check the file path in browser DevTools Network tab
- Verify Firebase SDK URLs are accessible

## Server-Side Changes (If Needed)

Since web doesn't support topic subscriptions, you may need to update your backend:

```python
# Example: Send to multiple tokens instead of topics
from firebase_admin import messaging

def send_to_web_users(tokens, title, body, data):
    messages = [
        messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data,
            token=token,
        )
        for token in tokens
    ]
    
    response = messaging.send_all(messages)
    print(f'Successfully sent {response.success_count} messages')
    return response
```

## Additional Resources

- [Firebase Cloud Messaging for Web](https://firebase.google.com/docs/cloud-messaging/js/client)
- [Web Push Notifications](https://web.dev/push-notifications-overview/)
- [Service Workers Guide](https://developers.google.com/web/fundamentals/primers/service-workers)

## Need Help?

If you encounter any issues:
1. Check the browser console for errors
2. Verify all configuration values match your Firebase project
3. Test in different browsers to isolate browser-specific issues
4. Check Firebase Console for any error messages

---

**Next Steps**: Follow Step 1 and Step 2 above to get your VAPID key and complete the setup!
