package com.example.rolify.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.example.rolify.R

class AllSoundWidgetListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        return AllSoundRemoteViewsFactory(this.applicationContext, appWidgetId)
    }
}

class AllSoundRemoteViewsFactory(
    private val context: Context,
    private val appWidgetId: Int
) : RemoteViewsService.RemoteViewsFactory {

    private var audios: List<RolifyAudio> = emptyList()

    override fun onCreate() {
        // Nothing heavy
    }

    override fun onDataSetChanged() {
        // Fetch from SharedPreferences
        audios = FlutterDataHelper.getAudios(context).apply {
            // Sort by name or any preferred order
            sortedBy { it.name.lowercase() }
        }
    }

    override fun onDestroy() {
        audios = emptyList()
    }

    override fun getCount(): Int = audios.size

    override fun getViewAt(position: Int): RemoteViews {
        val audio = audios[position]
        val views = RemoteViews(context.packageName, R.layout.widget_playlist_item)

        val displayName = if (audio.isActive) "✓ ${audio.name}" else audio.name
        views.setTextViewText(R.id.widget_playlist_name, displayName)

        val buttonIcon = if (audio.isActive) R.drawable.ic_baseline_check_24 else R.drawable.ic_baseline_add_24
        views.setImageViewResource(R.id.widget_playlist_button, buttonIcon)

        if (audio.isActive) {
            views.setInt(R.id.widget_playlist_item_container, "setBackgroundColor", context.getColor(R.color.widget_active_item_bg))
        } else {
            views.setInt(R.id.widget_playlist_item_container, "setBackgroundColor", 0)
        }


        val fillInIntent = Intent().apply {
            action = AllSoundWidget.ACTION_TOGGLE_AUDIO
            putExtra(AllSoundWidget.EXTRA_AUDIO_PATH, audio.path)
            putExtra(AllSoundWidget.EXTRA_AUDIO_NAME, audio.name)
        }
        views.setOnClickFillInIntent(R.id.widget_playlist_button, fillInIntent)
        views.setOnClickFillInIntent(R.id.widget_playlist_name, fillInIntent)


        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false
}
