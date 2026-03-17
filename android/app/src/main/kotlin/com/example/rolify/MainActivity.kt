package com.example.rolify

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity: AudioServiceActivity() {
    private val CHANNEL = "rolify/file_picker"
    private val COMPAT_CHANNEL = "rolify/compat"
    private val PICK_AUDIO_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickAudioFiles") {
                pendingResult = result
                openFilePicker()
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMPAT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getCompatibilityFlags") {
                result.success(
                    mapOf(
                        "isLegacyGpuDevice" to isLegacyGpuDevice(),
                        "isArmV7Device" to isArmV7Device(),
                        "isLowRamDevice" to isLowRamDevice(),
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "manufacturer" to Build.MANUFACTURER,
                        "model" to Build.MODEL,
                        "hardware" to Build.HARDWARE
                    )
                )
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isLowRamDevice(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.isLowRamDevice
    }

    private fun isLegacyGpuDevice(): Boolean {
        val model = Build.MODEL.lowercase(Locale.US)
        val device = Build.DEVICE.lowercase(Locale.US)
        val hardware = Build.HARDWARE.lowercase(Locale.US)
        val manufacturer = Build.MANUFACTURER.lowercase(Locale.US)
        val board = Build.BOARD.lowercase(Locale.US)

        val isNote3 = manufacturer.contains("samsung") &&
                (model.contains("n900") || device.contains("hlte") || board.contains("hlte"))

        val looksLikeOldQualcomm =
                hardware.contains("qcom") || hardware.contains("msm") || board.contains("msm")

        return isNote3 || (looksLikeOldQualcomm && isArmV7Device())
    }

    private fun isArmV7Device(): Boolean {
        return Build.SUPPORTED_ABIS.any { it.equals("armeabi-v7a", ignoreCase = true) }
    }

    private fun openFilePicker() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(intent, PICK_AUDIO_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_AUDIO_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val results = mutableListOf<Map<String, String>>()
                
                // Handle multiple files
                if (data.clipData != null) {
                    val count = data.clipData!!.itemCount
                    for (i in 0 until count) {
                        val uri = data.clipData!!.getItemAt(i).uri
                        processUri(uri)?.let { results.add(it) }
                    }
                } else if (data.data != null) {
                    // Handle single file
                    val uri = data.data!!
                    processUri(uri)?.let { results.add(it) }
                }
                
                pendingResult?.success(results)
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun processUri(uri: Uri): Map<String, String>? {
        try {
            // Take persistent permission
            val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION
            contentResolver.takePersistableUriPermission(uri, takeFlags)

            var name = ""
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) {
                        name = it.getString(nameIndex)
                    }
                }
            }
            
            if (name.isEmpty()) {
                name = uri.lastPathSegment ?: "Unknown Audio"
            }

            return mapOf(
                "name" to name,
                "path" to uri.toString()
            )
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }
}
