import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications (#65): delivers foreground notification
    // taps to the plugin.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "InstagramStories") {
      InstagramStoriesChannel.register(with: registrar)
    }
  }
}

/// Story card → Instagram Stories (#311), Instagram's documented pasteboard
/// + `instagram-stories://` flow. Replies false when Instagram isn't
/// installed, and the app falls back to the system share sheet.
enum InstagramStoriesChannel {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.leo.storyni/instagram_stories",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "share" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let path = args["imagePath"] as? String,
            let appId = args["appId"] as? String,
            let image = FileManager.default.contents(atPath: path),
            let url = URL(string: "instagram-stories://share?source_application=\(appId)"),
            UIApplication.shared.canOpenURL(url)
      else {
        result(false)
        return
      }
      var item: [String: Any] = ["com.instagram.sharedSticker.backgroundImage": image]
      if let link = args["contentUrl"] as? String {
        item["com.instagram.sharedSticker.contentURL"] = link
      }
      UIPasteboard.general.setItems(
        [item],
        options: [.expirationDate: Date().addingTimeInterval(5 * 60)]
      )
      UIApplication.shared.open(url) { opened in result(opened) }
    }
  }
}
