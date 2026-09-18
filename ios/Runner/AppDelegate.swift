import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The database and attachments are encrypted with a key stored in the
    // Keychain that is never restored to another device. Excluding them from
    // iCloud/iTunes backup avoids restoring data that could not be decrypted.
    if let documents = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    ).first {
      var url = documents
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try? url.setResourceValues(values)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TanoPrivacy") {
      let channel = FlutterMethodChannel(name: "tano/privacy", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "frameReady" else {
          result(FlutterMethodNotImplemented)
          return
        }
        TanoSnapshotCover.releaseActiveCovers()
        result(nil)
      }
    }
  }
}

// UIKit covers the last Flutter frame synchronously before a scene snapshot.
// Flutter releases this only after painting its own resumed privacy frame.
private enum TanoSnapshotCover {
  static var covers: [UIWindow: UIView] = [:]

  static func cover(_ scene: UIScene) {
    guard let windowScene = scene as? UIWindowScene else { return }
    for window in windowScene.windows where covers[window] == nil {
      let cover = UIView(frame: window.bounds)
      cover.backgroundColor = .systemBackground
      cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      window.addSubview(cover)
      covers[window] = cover
    }
  }

  static func releaseActiveCovers() {
    for window in Array(covers.keys) where window.windowScene?.activationState == .foregroundActive {
      covers.removeValue(forKey: window)?.removeFromSuperview()
    }
  }

  static func remove(_ scene: UIScene) {
    for window in Array(covers.keys) where window.windowScene === scene {
      covers.removeValue(forKey: window)?.removeFromSuperview()
    }
  }
}

class TanoSceneDelegate: FlutterSceneDelegate {
  override func sceneWillResignActive(_ scene: UIScene) {
    TanoSnapshotCover.cover(scene)
    super.sceneWillResignActive(scene)
  }

  override func sceneDidEnterBackground(_ scene: UIScene) {
    TanoSnapshotCover.cover(scene)
    super.sceneDidEnterBackground(scene)
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    TanoSnapshotCover.remove(scene)
    super.sceneDidDisconnect(scene)
  }
}
