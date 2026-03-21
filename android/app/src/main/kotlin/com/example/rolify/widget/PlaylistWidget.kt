package com.example.rolify.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.view.View
import androidx.core.net.toUri
import com.example.rolify.MainActivity
import com.example.rolify.R

class PlaylistWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.rolify.widget.playlist.ACTION_PLAY_PAUSE"
        const val ACTION_STOP_ALL = "com.example.rolify.widget.ACTION_STOP_ALL"
        const val ACTION_TOGGLE_PLAYLIST = "com.example.rolify.widget.playlist.ACTION_TOGGLE_PLAYLIST"
        const val ACTION_CYCLE_VOLUME = "com.example.rolify.widget.ACTION_CYCLE_VOLUME"
        const val EXTRA_PLAYLIST_ID = "extra_playlist_id"
        const val EXTRA_PLAYLIST_NAME = "extra_playlist_name"
        const val EXTRA_VOLUME = "extra_volume"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, PlaylistWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds.isNotEmpty()) {
                val provider = PlaylistWidget()
                for (id in appWidgetIds) {
                    provider.updateAppWidget(context, appWidgetManager, id)
                }
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_preset)

        val (activeAudios, activePlaylists) = FlutterDataHelper.getActiveCounts(context)
        
        val playIcon = if (FlutterDataHelper.isPlaying(context)) R.drawable.ic_widget_pause else R.drawable.ic_widget_play
        views.setImageViewResource(R.id.widget_play_pause, playIcon)

        if (activePlaylists > 0) {
            views.setTextViewText(R.id.widget_title, "Rolify - Playlists ($activePlaylists)")
        } else {
            views.setTextViewText(R.id.widget_title, "Rolify Playlists")
        }

        // Action: Play/Pause
        val playIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_PLAY_PAUSE
        }
        val playPendingIntent = PendingIntent.getBroadcast(
            context, 9, playIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_play_pause, playPendingIntent)


        // Action: Volume Cycle
        val volumeIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_CYCLE_VOLUME
        }
        val volumePendingIntent = PendingIntent.getBroadcast(
            context, 10, volumeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_master_volume_container, volumePendingIntent)

        val widgetPrefs = context.getSharedPreferences("WidgetCommandPrefs", Context.MODE_PRIVATE)
        val volume = widgetPrefs.getInt("volume", 100)
        views.setTextViewText(R.id.widget_master_volume_text, "$volume%")

        // Action: Stop
        val stopIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_STOP_ALL
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            context, 11, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_stop, stopPendingIntent)
        views.setViewVisibility(R.id.widget_stop, if (activeAudios > 0 || activePlaylists > 0) View.VISIBLE else View.GONE)

        // Intent to open App
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            data = "rolify://widget_playlist".toUri()
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context, 12, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title_container, openAppPendingIntent)

        // RemoteViewsService for the list of playlists
        val serviceIntent = Intent(context, PlaylistWidgetListService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = toUri(Intent.URI_INTENT_SCHEME).toUri()
        }
        views.setRemoteAdapter(R.id.widget_preset_list, serviceIntent)

        // PendingIntent for list item clicks
        val itemClickIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_TOGGLE_PLAYLIST
        }
        val itemClickPendingIntent = PendingIntent.getBroadcast(
            context, 13, itemClickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_preset_list, itemClickPendingIntent)

        // CRITICAL: updateAppWidget must be called BEFORE notifyAppWidgetViewDataChanged
        appWidgetManager.updateAppWidget(appWidgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_preset_list)
    }
}
