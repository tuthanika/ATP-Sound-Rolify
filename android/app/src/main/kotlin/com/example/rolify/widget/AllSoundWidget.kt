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

class AllSoundWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.rolify.widget.ACTION_PLAY_PAUSE"
        const val ACTION_STOP = "com.example.rolify.widget.ACTION_STOP"
        const val ACTION_TOGGLE_AUDIO = "com.example.rolify.widget.ACTION_TOGGLE_AUDIO"
        const val EXTRA_AUDIO_PATH = "extra_audio_path"
        const val EXTRA_AUDIO_NAME = "extra_audio_name"
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

        // Intents for buttons
        setButtonPendingIntent(context, views, R.id.widget_play_pause, ACTION_PLAY_PAUSE)
        setButtonPendingIntent(context, views, R.id.widget_stop, ACTION_STOP)

        // Intent to open App
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            data = "rolify://widget".toUri()
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title_container, openAppPendingIntent)

        // RemoteViewsService for the list of sounds
        val intent = Intent(context, AllSoundWidgetListService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = toUri(Intent.URI_INTENT_SCHEME).toUri()
        }
        views.setRemoteAdapter(R.id.widget_playlist_list, intent)

        // PendingIntent for list item clicks
        val clickIntent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = ACTION_TOGGLE_AUDIO
        }
        val clickPendingIntent = PendingIntent.getBroadcast(
            context, 0, clickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_playlist_list, clickPendingIntent)

        views.setTextViewText(R.id.widget_playlist_name, "Rolify - All Sounds")

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
