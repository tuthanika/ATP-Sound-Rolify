package com.example.rolify.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.example.rolify.R

class PlaylistWidgetListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        return PlaylistRemoteViewsFactory(this.applicationContext, appWidgetId)
    }
}

class PlaylistRemoteViewsFactory(
    private val context: Context,
    private val appWidgetId: Int
) : RemoteViewsService.RemoteViewsFactory {

    private var playlists: List<RolifyPlaylist> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        playlists = FlutterDataHelper.getPlaylists(context)
    }

    override fun onDestroy() {
        playlists = emptyList()
    }

    override fun getCount(): Int = playlists.size

    override fun getViewAt(position: Int): RemoteViews {
        val playlist = playlists[position]
        val views = RemoteViews(context.packageName, R.layout.widget_preset_item)

        val displayName = if (playlist.isActive) "✓ ${playlist.name}" else playlist.name
        views.setTextViewText(R.id.widget_preset_name, displayName)

        if (playlist.isActive) {
            views.setInt(R.id.widget_preset_item_container, "setBackgroundResource", R.drawable.widget_playlist_item_bg)
            views.setInt(R.id.widget_preset_item_container, "setBackgroundColor", context.getColor(R.color.widget_active_item_bg))
        } else {
            views.setInt(R.id.widget_preset_item_container, "setBackgroundResource", 0)
        }

        views.setImageViewResource(R.id.widget_preset_icon, R.drawable.ic_baseline_play_24)

        val fillInIntent = Intent().apply {
            action = PlaylistWidget.ACTION_TOGGLE_PLAYLIST
            putExtra(PlaylistWidget.EXTRA_PLAYLIST_ID, playlist.id)
            putExtra(PlaylistWidget.EXTRA_PLAYLIST_NAME, playlist.name)
        }
        views.setOnClickFillInIntent(R.id.widget_preset_icon, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false
}
