package com.example.rolify.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import com.example.rolify.MainActivity

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val audioPath = intent.getStringExtra(AllSoundWidget.EXTRA_AUDIO_PATH)
        val playlistId = intent.getStringExtra(PlaylistWidget.EXTRA_PLAYLIST_ID)
        val prefs = context.getSharedPreferences("WidgetCommandPrefs", Context.MODE_PRIVATE)

        when (action) {
            AllSoundWidget.ACTION_TOGGLE_AUDIO -> {
                sendAction(context, "play_audio", path = audioPath)
            }
            AllSoundWidget.ACTION_STOP_ALL, PlaylistWidget.ACTION_STOP_ALL -> {
                sendAction(context, "stop_all")
            }
            AllSoundWidget.ACTION_PLAY_PAUSE, PlaylistWidget.ACTION_PLAY_PAUSE -> {
                sendAction(context, "play_pause")
            }
            PlaylistWidget.ACTION_TOGGLE_PLAYLIST -> {
                sendAction(context, "play_playlist", id = playlistId)
            }
            AllSoundWidget.ACTION_CYCLE_VOLUME, PlaylistWidget.ACTION_CYCLE_VOLUME -> {
                val currentVolume = prefs.getInt("volume", 100)
                val nextVolume = when {
                    currentVolume < 25 -> 25
                    currentVolume < 50 -> 50
                    currentVolume < 75 -> 75
                    currentVolume < 100 -> 100
                    else -> 0
                }
                prefs.edit().putInt("volume", nextVolume).apply()
                sendAction(context, "set_master_volume", volume = nextVolume)

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
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(launchIntent)
        }
        
        // Refresh 1: Immediate feedback
        refreshWidgets(context)
        
        // Refresh 2: Delayed to catch Dart state changes
        Handler(Looper.getMainLooper()).postDelayed({
            refreshWidgets(context)
        }, 500)
    }
    
    private fun refreshWidgets(context: Context) {
        AllSoundWidget.updateAllWidgets(context)
        PlaylistWidget.updateAllWidgets(context)
    }
}
