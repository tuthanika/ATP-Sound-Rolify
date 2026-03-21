package com.example.rolify.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import com.example.rolify.MainActivity

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        when (action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                // First refresh after 3 seconds
                Handler(Looper.getMainLooper()).postDelayed({
                    refreshWidgets(context)
                }, 3000)
                // Second refresh after 10 seconds for safety
                Handler(Looper.getMainLooper()).postDelayed({
                    refreshWidgets(context)
                }, 10000)
            }
            AllSoundWidget.ACTION_PLAY_PAUSE, PlaylistWidget.ACTION_PLAY_PAUSE -> {
                MainActivity.sendSilentCommand(context, "play_pause")
                refreshWidgets(context)
            }
            AllSoundWidget.ACTION_STOP_ALL, PlaylistWidget.ACTION_STOP_ALL -> {
                MainActivity.sendSilentCommand(context, "stop_all")
                refreshWidgets(context)
            }
            AllSoundWidget.ACTION_TOGGLE_AUDIO -> {
                val path = intent.getStringExtra(AllSoundWidget.EXTRA_AUDIO_PATH) ?: return
                val name = intent.getStringExtra(AllSoundWidget.EXTRA_AUDIO_NAME) ?: ""
                MainActivity.sendSilentCommand(context, "toggle_audio", mapOf("path" to path, "name" to name))
                refreshWidgets(context)
            }
            PlaylistWidget.ACTION_TOGGLE_PLAYLIST -> {
                val id = intent.getStringExtra(PlaylistWidget.EXTRA_PLAYLIST_ID) ?: return
                val name = intent.getStringExtra(PlaylistWidget.EXTRA_PLAYLIST_NAME) ?: ""
                MainActivity.sendSilentCommand(context, "toggle_playlist", mapOf("id" to id, "name" to name))
                refreshWidgets(context)
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
                MainActivity.sendSilentCommand(context, "set_master_volume", mapOf("volume" to newVolume))
                refreshWidgets(context)
            }
        }
    }

    private fun refreshWidgets(context: Context) {
        AllSoundWidget.updateAllWidgets(context)
        PlaylistWidget.updateAllWidgets(context)
    }
}
