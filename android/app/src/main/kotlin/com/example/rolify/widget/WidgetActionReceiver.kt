package com.example.rolify.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.rolify.MainActivity

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        
        val prefs = context.getSharedPreferences("WidgetCommandPrefs", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        
        when (action) {
            AllSoundWidget.ACTION_PLAY_PAUSE, PlaylistWidget.ACTION_PLAY_PAUSE -> {
                editor.putString("command", "play_pause")
            }
            AllSoundWidget.ACTION_STOP, PlaylistWidget.ACTION_STOP -> {
                editor.putString("command", "stop_all")
            }
            AllSoundWidget.ACTION_TOGGLE_AUDIO -> {
                val path = intent.getStringExtra(AllSoundWidget.EXTRA_AUDIO_PATH) ?: ""
                editor.putString("command", "play_audio")
                editor.putString("path", path)
            }
            PlaylistWidget.ACTION_TOGGLE_PLAYLIST -> {
                val id = intent.getStringExtra(PlaylistWidget.EXTRA_PLAYLIST_ID) ?: ""
                editor.putString("command", "play_playlist")
                editor.putString("id", id)
            }
        }
        editor.apply()
        
        // Launch or Wake App
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(launchIntent)
    }
}
