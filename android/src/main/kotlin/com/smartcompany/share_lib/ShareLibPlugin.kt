package com.smartcompany.share_lib

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Android: 카카오톡으로 이미지(사진 메시지) 직접 공유 */
class ShareLibPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
  private var channel: MethodChannel? = null
  private var activity: Activity? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "share_lib/share")
    channel?.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "shareImageToKakaoTalk" -> {
        val path = call.argument<String>("path")
        val text = call.argument<String>("text")
        if (path.isNullOrBlank()) {
          result.error("invalid_args", "path is required", null)
          return
        }
        try {
          shareImageToKakaoTalk(path, text)
          result.success(true)
        } catch (e: Exception) {
          result.error(
            "share_failed",
            e.message ?: e.javaClass.simpleName,
            e.stackTraceToString(),
          )
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun shareImageToKakaoTalk(path: String, text: String?) {
    val act = activity ?: throw IllegalStateException("Activity not available")
    val file = File(path)
    if (!file.exists()) {
      throw IllegalStateException("Image file not found: $path")
    }

    val authority = "${act.packageName}.share_lib.fileprovider"
    val uri: Uri = FileProvider.getUriForFile(act, authority, file)

    val sendIntent = Intent(Intent.ACTION_SEND).apply {
      type = "image/png"
      setPackage(KAKAO_TALK_PACKAGE)
      putExtra(Intent.EXTRA_STREAM, uri)
      clipData = android.content.ClipData.newUri(act.contentResolver, "share", uri)
      if (!text.isNullOrBlank()) {
        putExtra(Intent.EXTRA_TEXT, text)
        // Some receivers expect caption under EXTRA_SUBJECT too.
        putExtra(Intent.EXTRA_SUBJECT, text.take(80))
      }
      addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    try {
      act.grantUriPermission(
        KAKAO_TALK_PACKAGE,
        uri,
        Intent.FLAG_GRANT_READ_URI_PERMISSION,
      )
    } catch (_: Exception) {
      // ignore
    }

    val pm = act.packageManager
    val resolved = sendIntent.resolveActivity(pm)
    if (resolved != null) {
      act.startActivity(sendIntent)
      return
    }

    // Package-targeted resolve failed — still try chooser filtered to Kakao if possible.
    val chooser = Intent.createChooser(sendIntent, null)
    if (chooser.resolveActivity(pm) == null) {
      throw IllegalStateException("No app can handle image share (KakaoTalk?)")
    }
    act.startActivity(chooser)
  }

  companion object {
    private const val KAKAO_TALK_PACKAGE = "com.kakao.talk"
  }
}
