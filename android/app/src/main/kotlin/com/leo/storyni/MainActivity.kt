package com.leo.storyni

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Story card → Instagram Stories (#311), Instagram's documented
        // ADD_TO_STORY intent. Replies false when Instagram can't take it,
        // and the app falls back to the system share sheet.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.leo.storyni/instagram_stories",
        ).setMethodCallHandler { call, result ->
            if (call.method != "share") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val path = call.argument<String>("imagePath")
            val appId = call.argument<String>("appId")
            if (path == null || appId == null) {
                result.success(false)
                return@setMethodCallHandler
            }
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.story_share",
                File(path),
            )
            val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                putExtra("source_application", appId)
                setDataAndType(uri, "image/png")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                call.argument<String>("contentUrl")?.let {
                    putExtra("content_url", it)
                }
            }
            if (packageManager.resolveActivity(intent, 0) == null) {
                result.success(false)
                return@setMethodCallHandler
            }
            grantUriPermission(
                "com.instagram.android",
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
            startActivity(intent)
            result.success(true)
        }
    }
}
