package com.ruptura.streaming

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.util.Log
import android.util.Size
import io.github.thibaultbee.streampack.core.configuration.mediadescriptor.UriMediaDescriptor as createUriMediaDescriptor
import io.github.thibaultbee.streampack.core.interfaces.ICloseableStreamer
import io.github.thibaultbee.streampack.core.interfaces.IStreamer
import io.github.thibaultbee.streampack.core.interfaces.startStream
import io.github.thibaultbee.streampack.core.streamers.single.ISingleStreamer
import io.github.thibaultbee.streampack.core.streamers.single.IVideoSingleStreamer
import io.github.thibaultbee.streampack.core.streamers.single.VideoConfig
import io.github.thibaultbee.streampack.core.streamers.utils.MediaProjectionUtils
import io.github.thibaultbee.streampack.services.MediaProjectionService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

class RupturaStreamerPlugin(godot: Godot) : GodotPlugin(godot) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var connection: ServiceConnection? = null
    private var streamer: ISingleStreamer? = null
    private var pendingPublishUrl: String = ""
    private var pendingWatchUrl: String = ""
    private var pendingWidth: Int = 1280
    private var pendingHeight: Int = 720
    private var pendingFps: Int = 30
    private var pendingBitrate: Int = 2_400_000
    @Volatile
    private var stopInProgress: Boolean = false
    private var status: String = "idle"

    override fun getPluginName() = "RupturaStreamer"

    @UsedByGodot
    fun startStream(publishUrl: String, watchUrl: String, width: Int, height: Int, fps: Int, bitrate: Int): String {
        if (stopInProgress) {
            return "ERRO:ENCERRANDO"
        }
        if (streamer != null && status != "idle") {
            return "ERRO:STREAM_ATIVO"
        }
        if (publishUrl.isBlank()) {
            status = "publish URL vazia"
            return "ERRO:URL"
        }
        pendingPublishUrl = publishUrl
        pendingWatchUrl = watchUrl
        val adjustedSize = adjustedVideoSize(width, height)
        pendingWidth = adjustedSize.width
        pendingHeight = adjustedSize.height
        pendingFps = fps.coerceIn(20, 30)
        pendingBitrate = bitrate.coerceIn(350_000, 4_000_000)
        status = "pedindo permissao"
        Log.i(TAG, "Requesting MediaProjection for $pendingPublishUrl")
        val hostActivity = activity ?: run {
            status = "activity indisponivel"
            return "ERRO:ACTIVITY"
        }
        hostActivity.runOnUiThread {
            hostActivity.startActivityForResult(
                createScreenCaptureIntent(hostActivity),
                REQUEST_MEDIA_PROJECTION
            )
        }
        return "OK:PERMISSION"
    }

    @UsedByGodot
    fun stopStream(): String {
        if (stopInProgress) {
            return "OK:STOPPING"
        }
        stopInProgress = true
        status = "encerrando"
        val currentStreamer = streamer
        scope.launch {
            try {
                currentStreamer?.stopStream()
                (currentStreamer as? ICloseableStreamer)?.close()
                currentStreamer?.release()
            } catch (t: Throwable) {
                Log.w(TAG, "Failed to stop streamer cleanly", t)
            } finally {
                streamer = null
                val hostActivity = activity
                withContext(Dispatchers.Main) {
                    hostActivity?.let { host ->
                        connection?.let {
                            try {
                                host.unbindService(it)
                            } catch (_: Throwable) {
                            }
                        }
                        connection = null
                        host.stopService(Intent(host, RupturaMediaProjectionService::class.java))
                    }
                }
                status = "idle"
                stopInProgress = false
            }
        }
        return "OK:STOP"
    }

    @UsedByGodot
    fun getStatus(): String {
        return status
    }

    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onMainActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_MEDIA_PROJECTION) {
            return
        }
        Log.i(TAG, "MediaProjection result code=$resultCode hasData=${data != null}")
        if (resultCode != Activity.RESULT_OK || data == null) {
            status = "permissao negada"
            Log.w(TAG, "MediaProjection permission denied")
            return
        }
        val hostActivity = activity ?: run {
            status = "activity indisponivel"
            return
        }
        status = "conectando service"
        Log.i(TAG, "MediaProjection permission granted, binding service")
        connection = MediaProjectionService.bindService(
            context = hostActivity,
            serviceClass = RupturaMediaProjectionService::class.java,
            resultCode = resultCode,
            resultData = data,
            onServiceCreated = { createdStreamer ->
                streamer = createdStreamer as? ISingleStreamer
                Log.i(TAG, "MediaProjection service created")
                configureAndStart(createdStreamer)
            },
            onServiceDisconnected = {
                streamer = null
                status = if (stopInProgress) "encerrando" else "service desconectado"
                Log.w(TAG, "MediaProjection service disconnected")
            }
        )
    }

    override fun onMainDestroy() {
        stopStream()
        scope.cancel()
        super.onMainDestroy()
    }

    private fun configureAndStart(createdStreamer: IStreamer) {
        val single = createdStreamer as? ISingleStreamer
        val video = createdStreamer as? IVideoSingleStreamer
        if (single == null || video == null) {
            status = "streamer incompativel"
            return
        }
        scope.launch {
            try {
                status = "configurando encoder"
                Log.i(TAG, "Configuring encoder ${pendingWidth}x$pendingHeight ${pendingFps}fps ${pendingBitrate}bps")
                video.setVideoConfig(
                    VideoConfig(
                        startBitrate = pendingBitrate,
                        resolution = Size(pendingWidth, pendingHeight),
                        fps = pendingFps,
                        gopDurationInS = 1.0f
                    )
                )
                status = "publicando"
                Log.i(TAG, "Publishing RTMP/FLV to $pendingPublishUrl")
                single.startStream(
                    createUriMediaDescriptor(
                        Uri.parse(pendingPublishUrl),
                        emptyList()
                    )
                )
                streamer = single
                status = "publicado, aguardando video"
                Log.i(TAG, "RTMP publisher started; waiting for HLS media")
                if (waitForHlsMedia(pendingWatchUrl)) {
                    status = "ao vivo confirmado"
                    Log.i(TAG, "HLS media confirmed at $pendingWatchUrl")
                } else {
                    status = "erro: servidor nao recebeu video"
                    Log.e(TAG, "HLS media did not become available at $pendingWatchUrl")
                }
            } catch (t: Throwable) {
                val message = t.message ?: "sem detalhe"
                status = "erro ${t.javaClass.simpleName}: $message"
                Log.e(TAG, "Streaming failed", t)
            }
        }
    }

    private fun createScreenCaptureIntent(hostActivity: Activity): Intent {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val manager = hostActivity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            return manager.createScreenCaptureIntent(MediaProjectionConfig.createConfigForDefaultDisplay())
        }
        return MediaProjectionUtils.createScreenCaptureIntent(hostActivity)
    }

    private fun adjustedVideoSize(requestedWidth: Int, requestedHeight: Int): Size {
        val maxWidth = requestedWidth.coerceIn(320, 1280)
        val maxHeight = requestedHeight.coerceIn(180, 720)
        val hostActivity = activity ?: return Size(even(maxWidth), even(maxHeight))
        val bounds = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            hostActivity.windowManager.currentWindowMetrics.bounds
        } else {
            @Suppress("DEPRECATION")
            android.graphics.Rect().also {
                val metrics = android.util.DisplayMetrics()
                @Suppress("DEPRECATION")
                hostActivity.windowManager.defaultDisplay.getRealMetrics(metrics)
                it.set(0, 0, metrics.widthPixels, metrics.heightPixels)
            }
        }
        val sourceWidth = bounds.width().coerceAtLeast(1)
        val sourceHeight = bounds.height().coerceAtLeast(1)
        val sourceAspect = sourceWidth.toFloat() / sourceHeight.toFloat()
        val limitAspect = maxWidth.toFloat() / maxHeight.toFloat()
        val target = if (sourceAspect >= limitAspect) {
            Size(maxWidth, even((maxWidth / sourceAspect).toInt().coerceIn(180, maxHeight)))
        } else {
            Size(even((maxHeight * sourceAspect).toInt().coerceIn(320, maxWidth)), maxHeight)
        }
        Log.i(TAG, "Adjusted stream size ${target.width}x${target.height} for display ${sourceWidth}x${sourceHeight}")
        return target
    }

    private fun even(value: Int): Int {
        return if (value % 2 == 0) value else value + 1
    }

    private suspend fun waitForHlsMedia(watchUrl: String): Boolean = withContext(Dispatchers.IO) {
        if (watchUrl.isBlank()) {
            return@withContext false
        }
        repeat(HLS_PROBE_ATTEMPTS) {
            if (hasHlsPlaylist(watchUrl)) {
                return@withContext true
            }
            delay(HLS_PROBE_INTERVAL_MS)
        }
        false
    }

    private fun hasHlsPlaylist(watchUrl: String): Boolean {
        var connection: HttpURLConnection? = null
        return try {
            connection = URL(watchUrl).openConnection() as HttpURLConnection
            connection.connectTimeout = HLS_PROBE_TIMEOUT_MS
            connection.readTimeout = HLS_PROBE_TIMEOUT_MS
            connection.useCaches = false
            connection.setRequestProperty("Cache-Control", "no-cache")
            if (connection.responseCode !in 200..299) {
                false
            } else {
                val playlist = connection.inputStream.bufferedReader().use { it.readText() }
                playlist.contains("#EXTM3U") && (
                    playlist.contains("#EXT-X-STREAM-INF") ||
                    playlist.contains("#EXT-X-MEDIA-SEQUENCE") ||
                    playlist.contains("#EXTINF") ||
                    playlist.contains("#EXT-X-PART")
                )
            }
        } catch (_: Throwable) {
            false
        } finally {
            connection?.disconnect()
        }
    }

    companion object {
        private const val TAG = "RupturaStreamer"
        private const val REQUEST_MEDIA_PROJECTION = 7701
        private const val HLS_PROBE_ATTEMPTS = 60
        private const val HLS_PROBE_INTERVAL_MS = 500L
        private const val HLS_PROBE_TIMEOUT_MS = 1200
    }
}
