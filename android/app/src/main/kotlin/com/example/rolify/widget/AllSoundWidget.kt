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

class AllSoundWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.rolify.widget.ACTION_PLAY_PAUSE"
        const val ACTION_STOP_ALL = "com.example.rolify.widget.ACTION_STOP_ALL"
        const val ACTION_TOGGLE_AUDIO = "com.example.rolify.widget.ACTION_TOGGLE_AUDIO"
        const val ACTION_CYCLE_VOLUME = "com.example.rolify.widget.ACTION_CYCLE_VOLUME"
        const val EXTRA_AUDIO_PATH = "extra_audio_path"
        const val EXTRA_AUDIO_NAME = "extra_audio_name"
        const val EXTRA_VOLUME = "extra_volume"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, AllSoundWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds.isNotEmpty()) {
                val intent = Intent(context, AllSoundWidget::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                }
                context.sendBroadcast(intent)
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_soundaura_list)
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
        val views = RemoteViews(context.packageName, R.layout.widget_soundaura)

        // Action: Play/Pause
        val playIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_PLAY_PAUSE
        }
        val playPendingIntent = PendingIntent.getBroadcast(
            context, 1, playIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_play_pause, playPendingIntent)

        val (activeAudios, activePlaylists) = FlutterDataHelper.getActiveCounts(context)
        if (activeAudios > 0) {
            views.setTextViewText(R.id.widget_playlist_name, "Rolify - Sounds ($activeAudios)")
            views.setTextViewText(R.id.widget_status, "Playing")
        } else {
            views.setTextViewText(R.id.widget_playlist_name, "Rolify - All Sounds")
            views.setTextViewText(R.id.widget_status, "Stopped")
        }

        // Action: Volume Cycle
        val volumeIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_CYCLE_VOLUME
        }
        val volumePendingIntent = PendingIntent.getBroadcast(
            context, 2, volumeIntent,
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
            context, 3, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_stop, stopPendingIntent)
        views.setViewVisibility(R.id.widget_stop, if (activeAudios > 0) View.VISIBLE else View.GONE)

        // Intent to open App
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            data = "rolify://widget".toUri()
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context, 4, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title_container, openAppPendingIntent)

        // RemoteViewsService for the list of sounds
        val serviceIntent = Intent(context, AllSoundWidgetListService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = toUri(Intent.URI_INTENT_SCHEME).toUri()
        }
        views.setRemoteAdapter(R.id.widget_soundaura_list, serviceIntent)

        // PendingIntent for list item clicks
        val itemClickIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_TOGGLE_AUDIO
        }
        val itemClickPendingIntent = PendingIntent.getBroadcast(
            context, 5, itemClickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_soundaura_list, itemClickPendingIntent)

        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_soundaura_list)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
