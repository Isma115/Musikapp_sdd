package com.example.sdd_music_simple

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private companion object {
        const val CHANNEL = "sdd_music_simple/storage_permissions"
        const val AUDIO_PERMISSION_REQUEST = 1001
    }

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "requestAudioAccess") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    result.success(true)
                    return@setMethodCallHandler
                }

                val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    arrayOf(Manifest.permission.READ_MEDIA_AUDIO)
                } else if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                    arrayOf(
                        Manifest.permission.READ_EXTERNAL_STORAGE,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    )
                } else {
                    arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
                }

                if (permissions.all {
                        checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
                    }
                ) {
                    result.success(true)
                    return@setMethodCallHandler
                }

                pendingPermissionResult = result
                requestPermissions(permissions, AUDIO_PERMISSION_REQUEST)
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != AUDIO_PERMISSION_REQUEST) {
            return
        }

        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }
}
