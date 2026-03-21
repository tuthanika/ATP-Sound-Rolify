package com.example.rolify.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import androidx.core.net.toUri
import com.example.rolify.MainActivity
import com.example.rolify.R

class PlaylistWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.rolify.widget.playlist.ACTION_PLAY_PAUSE"
        const val ACTION_STOP = "com.example.rolify.widget.playlist.ACTION_STOP"
        const val ACTION_TOGGLE_PLAYLIST = "com.example.rolify.widget.playlist.ACTION_TOGGLE_PLAYLIST"
        const val ACTION_TOGGLE_VOLUME_SLIDER = "com.example.rolify.widget.playlist.ACTION_TOGGLE_VOLUME_SLIDER"
        const val ACTION_SET_VOLUME = "com.example.rolify.widget.playlist.ACTION_SET_VOLUME"
        const val EXTRA_PLAYLIST_ID = "extra_playlist_id"
        const val EXTRA_PLAYLIST_NAME = "extra_playlist_name"
        const val EXTRA_VOLUME = "extra_volume"
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
        if (activePlaylists > 0) {
            views.setTextViewText(R.id.widget_title, "Rolify - Playlists ($activePlaylists)")
        } else {
            views.setTextViewText(R.id.widget_title, "Rolify Playlists")
        }

        // Action: Volume Cycle
        val volumeIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_CYCLE_VOLUME
        }
        val volumePendingIntent = PendingIntent.getBroadcast(
            context, 0, volumeIntent,
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
            context, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_stop, stopPendingIntent)
        views.setViewVisibility(R.id.widget_stop, if (activeAudios > 0 || activePlaylists > 0) View.VISIBLE else View.GONE)


        // Volume slider buttons
        val volumeButtons = arrayOf(
            R.id.widget_volume_10 to 10, R.id.widget_volume_20 to 20, R.id.widget_volume_30 to 30,
            R.id.widget_volume_40 to 40, R.id.widget_volume_50 to 50, R.id.widget_volume_60 to 60,
            R.id.widget_volume_70 to 70, R.id.widget_volume_80 to 80, R.id.widget_volume_90 to 90,
            R.id.widget_volume_100 to 100
        )
        for ((viewId, volume) in volumeButtons) {
            val intent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = ACTION_SET_VOLUME
                putExtra(EXTRA_VOLUME, volume)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, viewId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(viewId, pendingIntent)
        }

        // Intent to open App
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            data = "rolify://widget_playlist".toUri()
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title_container, openAppPendingIntent)

        // RemoteViewsService for the list of playlists
        val intent = Intent(context, PlaylistWidgetListService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = toUri(Intent.URI_INTENT_SCHEME).toUri()
        }
        views.setRemoteAdapter(R.id.widget_preset_list, intent)

        // PendingIntent for list item clicks
        val clickIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_TOGGLE_PLAYLIST
        }
        val clickPendingIntent = PendingIntent.getBroadcast(
            context, 0, clickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_preset_list, clickPendingIntent)

        views.setTextViewText(R.id.widget_title, "Rolify Playlists")

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun setButtonPendingIntent(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        action: String
    ) {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            setAction(action)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, viewId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(viewId, pendingIntent)
    }
}
