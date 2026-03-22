package com.tuthanika.rolify.plus.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat
import android.content.ComponentName
import android.util.Log
import com.tuthanika.rolify.plus.MainActivity

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        Log.d("RolifyWidget", "onReceive: $action")

        when (action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                refreshWidgets(context)
            }
            AllSoundWidget.ACTION_PLAY_PAUSE, PlaylistWidget.ACTION_PLAY_PAUSE -> {
                sendAction(context, "play_pause")
            }
            AllSoundWidget.ACTION_STOP_ALL, PlaylistWidget.ACTION_STOP_ALL -> {
                sendAction(context, "stop_all")
            }
            AllSoundWidget.ACTION_TOGGLE_AUDIO -> {
                val path = intent.getStringExtra(AllSoundWidget.EXTRA_AUDIO_PATH) ?: return
                sendAction(context, "play_audio", path = path)
            }
            PlaylistWidget.ACTION_TOGGLE_PLAYLIST -> {
                val id = intent.getStringExtra(PlaylistWidget.EXTRA_PLAYLIST_ID) ?: return
                sendAction(context, "play_playlist", id = id)
            }
            AllSoundWidget.ACTION_CYCLE_VOLUME, PlaylistWidget.ACTION_CYCLE_VOLUME -> {
                val widgetPrefs = context.getSharedPreferences("WidgetCommandPrefs", Context.MODE_PRIVATE)
                val currentVolume = widgetPrefs.getInt("volume", 100)
                val newVolume = when (currentVolume) {
                    100 -> 75
                    75 -> 50
                    50 -> 25
                    25 -> 0
                    else -> 100
                }
                widgetPrefs.edit().putInt("volume", newVolume).apply()
                sendAction(context, "set_master_volume", volume = newVolume)
            }
        }
    }

    private fun sendAction(context: Context, command: String, path: String? = null, id: String? = null, volume: Int? = null) {
        val extras = Bundle().apply {
            putString("path", path)
            putString("id", id)
            volume?.let { putInt("volume", it) }
        }

        Log.d("RolifyWidget", "Sending action: $command")

        // Path 1: If MainActivity is alive, use MethodChannel (very fast)
        if (MainActivity.instance != null) {
            Log.d("RolifyWidget", "Sending via MainActivity instance")
            MainActivity.sendSilentCommand(command, path, id, volume)
        }

        // Path 2: Always try MediaBrowser as well (handles background service better)
        var mediaBrowser: MediaBrowserCompat? = null
        
        mediaBrowser = MediaBrowserCompat(
            context,
            ComponentName(context.packageName, "com.ryanheise.audioservice.AudioService"),
            object : MediaBrowserCompat.ConnectionCallback() {
                override fun onConnected() {
                    Log.d("RolifyWidget", "Connected to AudioService")
                    try {
                        val browser = mediaBrowser ?: return
                        val controller = MediaControllerCompat(context, browser.sessionToken!!)
                        controller.transportControls.sendCustomAction(command, extras)
                        
                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                            if (browser.isConnected) {
                                browser.disconnect()
                                Log.d("RolifyWidget", "Disconnected after action")
                            }
                        }, 1000)
                    } catch (e: Exception) {
                        Log.e("RolifyWidget", "Error in MediaBrowser path: ${e.message}")
                        mediaBrowser?.let { if (it.isConnected) it.disconnect() }
                    }
                }

                override fun onConnectionFailed() {
                    Log.e("RolifyWidget", "Connection to AudioService FAILED")
                }
            },
            null
        )
        mediaBrowser.connect()
        
        // Path 3: Ensure service is running silently
        try {
            val serviceIntent = Intent(context, Class.forName("com.ryanheise.audioservice.AudioService"))
            context.startService(serviceIntent)
        } catch (e: Exception) {
            Log.e("RolifyWidget", "Failed to start service: ${e.message}")
        }

        refreshWidgets(context)
    }

    private fun refreshWidgets(context: Context) {
        AllSoundWidget.updateAllWidgets(context)
        PlaylistWidget.updateAllWidgets(context)
    }
}
