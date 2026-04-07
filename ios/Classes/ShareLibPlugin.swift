import Flutter
import UIKit

/// Registers the native [ASAuthorizationAppleIDButton] platform view.
@objc public class ShareLibPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = NativeAppleSignInButtonFactory(messenger: registrar.messenger())
    registrar.register(
      factory,
      withId: "share_lib/native_apple_sign_in_button"
    )
  }
}
