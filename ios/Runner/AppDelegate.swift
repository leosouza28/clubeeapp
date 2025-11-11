import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var initialLink: String?
  private var deepLinkChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    
    // Setup deep link channel FIRST
    deepLinkChannel = FlutterMethodChannel(
      name: "app.clubee/deeplink",
      binaryMessenger: controller.binaryMessenger
    )
    
    deepLinkChannel?.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "getInitialLink" {
        result(self?.initialLink)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle deep links when app is already running
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    deepLinkChannel?.invokeMethod("routeUpdated", arguments: url.absoluteString)
    return true
  }
  
  // Handle universal links
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      deepLinkChannel?.invokeMethod("routeUpdated", arguments: url.absoluteString)
      return true
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
