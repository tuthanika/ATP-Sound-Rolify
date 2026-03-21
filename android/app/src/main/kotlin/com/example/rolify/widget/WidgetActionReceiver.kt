package com.example.rolify.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
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
            AllSoundWidget.ACTION_TOGGLE_VOLUME_SLIDER, PlaylistWidget.ACTION_TOGGLE_VOLUME_SLIDER -> {
                val widgetPrefs = context.getSharedPreferences("WidgetPrefs", Context.MODE_PRIVATE)
                val isVisible = widgetPrefs.getBoolean("volume_slider_visible", false)
                widgetPrefs.edit().putBoolean("volume_slider_visible", !isVisible).apply()
                updateAllWidgets(context)
                return // Don't launch app for just toggling slider
            }
            AllSoundWidget.ACTION_SET_VOLUME, PlaylistWidget.ACTION_SET_VOLUME -> {
                val volume = intent.getIntExtra("extra_volume", 100)
                val widgetPrefs = context.getSharedPreferences("WidgetPrefs", Context.MODE_PRIVATE)
                widgetPrefs.edit().putInt("master_volume", volume).putBoolean("volume_slider_visible", false).apply()
                
                editor.putString("command", "set_volume")
                editor.putInt("volume", volume)
                updateAllWidgets(context)
            }

        }
        editor.apply()
        
        // Launch or Wake App
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(launchIntent)
    }

    private fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        
        val allSoundWidget = ComponentName(context, AllSoundWidget::class.java)
        val allSoundIds = appWidgetManager.getAppWidgetIds(allSoundWidget)
        if (allSoundIds.isNotEmpty()) {
            val intent = Intent(context, AllSoundWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, allSoundIds)
            }
            context.sendBroadcast(intent)
        }

        val playlistWidget = ComponentName(context, PlaylistWidget::class.java)
        val playlistIds = appWidgetManager.getAppWidgetIds(playlistWidget)
        if (playlistIds.isNotEmpty()) {
            val intent = Intent(context, PlaylistWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, playlistIds)
            }
            context.sendBroadcast(intent)
        }
    }
}
