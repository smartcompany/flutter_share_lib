import AuthenticationServices
import Flutter
import UIKit

final class NativeAppleSignInButtonFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let map = args as? [String: Any]
    return NativeAppleSignInButtonPlatformView(
      frame: frame,
      viewId: viewId,
      args: map,
      messenger: messenger
    )
  }
}

/// Hosts Apple's system [ASAuthorizationAppleIDButton] (HIG-compliant).
final class NativeAppleSignInButtonPlatformView: NSObject, FlutterPlatformView {
  private let button: ASAuthorizationAppleIDButton
  private let channel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewId: Int64,
    args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    let styleRaw = args?["style"] as? Int ?? 0
    let corner = args?["cornerRadius"] as? CGFloat ?? 8

    let style: ASAuthorizationAppleIDButton.Style
    switch styleRaw {
    case 1:
      style = .white
    case 2:
      style = .whiteOutline
    default:
      style = .black
    }

    button = ASAuthorizationAppleIDButton(type: .signIn, style: style)
    button.cornerRadius = corner

    channel = FlutterMethodChannel(
      name: "share_lib/native_apple_sign_in_button_\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
  }

  @objc private func onTap() {
    channel.invokeMethod("tap", arguments: nil)
  }

  func view() -> UIView {
    button
  }
}
