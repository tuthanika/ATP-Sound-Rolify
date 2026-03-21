package com.tuthanika.rolify.plus.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.tuthanika.rolify.plus.MainActivity

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

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
        if (MainActivity.instance != null) {
            MainActivity.sendSilentCommand(command, path, id, volume)
        } else {
            val prefs = context.getSharedPreferences("WidgetCommandPrefs", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString("command", command)
                putString("path", path)
                putString("id", id)
                volume?.let { putInt("volume", it) }
                apply()
            }
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(launchIntent)
        }
        
        // Immediate refresh
        refreshWidgets(context)
    }

    private fun refreshWidgets(context: Context) {
        AllSoundWidget.updateAllWidgets(context)
        PlaylistWidget.updateAllWidgets(context)
    }
}
