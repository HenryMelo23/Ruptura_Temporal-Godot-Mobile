package com.ruptura.streaming

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

class RupturaStreamerPlugin(godot: Godot) : GodotPlugin(godot) {
    private var status: String = "streaming nativo indisponivel nesta build"

    override fun getPluginName() = "RupturaStreamer"

    @UsedByGodot
    fun startStream(publishUrl: String, watchUrl: String, width: Int, height: Int, fps: Int, bitrate: Int): String {
        status = "streaming nativo indisponivel nesta build"
        Log.w(TAG, "Native Android streaming is disabled in this build")
        return "ERRO:STREAMING_INDISPONIVEL"
    }

    @UsedByGodot
    fun stopStream(): String {
        status = "idle"
        return "OK:STOP"
    }

    @UsedByGodot
    fun getStatus(): String {
        return status
    }

    @UsedByGodot
    fun getDeviceProfile(): String {
        return "standard"
    }

    @UsedByGodot
    fun installUpdate(apkPath: String): String {
        val hostActivity = activity ?: return "ERRO:ACTIVITY"
        return try {
            val apk = File(apkPath).canonicalFile
            val updateRoot = File(hostActivity.filesDir, "updates").canonicalFile
            val updatePrefix = updateRoot.path + File.separator
            if (!apk.isFile || !apk.path.startsWith(updatePrefix) || !apk.name.endsWith(".apk", ignoreCase = true)) {
                Log.w(TAG, "Rejected update path: ${apk.path}")
                return "ERRO:APK_INVALIDO"
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !hostActivity.packageManager.canRequestPackageInstalls()) {
                val permissionIntent = Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${hostActivity.packageName}")
                )
                hostActivity.startActivity(permissionIntent)
                return "PERMISSION_REQUIRED"
            }
            val apkUri = FileProvider.getUriForFile(
                hostActivity,
                "${hostActivity.packageName}.fileprovider",
                apk
            )
            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            hostActivity.startActivity(installIntent)
            "OK:INSTALLER"
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to open Android update installer", t)
            "ERRO:${t.javaClass.simpleName}"
        }
    }

    companion object {
        private const val TAG = "RupturaStreamer"
    }
}
