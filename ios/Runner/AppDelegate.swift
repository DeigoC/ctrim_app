import UIKit
import Flutter
import FirebaseAuth
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     if #available(iOS 10.0, *) {
              UNUserNotificationCenter.current().delegate = self
      }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // https://stackoverflow.com/questions/57048800/flutter-if-app-delegate-swizzling-is-disabled-remote-notifications-received-by
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Pass device token to auth
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)

    // Pass device token to messaging
    Messaging.messaging().apnsToken = deviceToken

    return super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
