package com.tuthanika.rolify.plus.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.tuthanika.rolify.plus.R

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

        views.setTextViewText(R.id.widget_preset_name, playlist.name)

        // 2. Đọc danh sách đang phát từ Flutter SharedPreferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Lấy CSV String và split thành List thay vì dùng getStringSet (Gây crash)
        val playingCsv = prefs.getString("flutter.widget_playing_paths_csv", "") ?: ""
        val playingPaths = playingCsv.split(",,")

        // 3. Kiểm tra và set Icon Play / Stop
        // The widget item is playing ONLY if all its sounds are in the playing pool
        val playlistAudios = playlist.audios.map { it.path }
        val isPlaying = playlistAudios.isNotEmpty() && playingPaths.containsAll(playlistAudios)

        if (playlist.isActive || isPlaying) {
            views.setInt(R.id.widget_preset_item_container, "setBackgroundResource", R.drawable.widget_playlist_item_bg)
            views.setInt(R.id.widget_preset_item_container, "setBackgroundColor", context.getColor(R.color.widget_active_item_bg))
        } else {
            views.setInt(R.id.widget_preset_item_container, "setBackgroundResource", 0)
            views.setInt(R.id.widget_preset_item_container, "setBackgroundColor", 0)
        }

        val buttonIcon = if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_baseline_play_24
        views.setImageViewResource(R.id.widget_preset_icon, buttonIcon)

        val fillInIntent = Intent().apply {
            action = PlaylistWidget.ACTION_TOGGLE_PLAYLIST
            putExtra(PlaylistWidget.EXTRA_PLAYLIST_ID, playlist.id)
            putExtra(PlaylistWidget.EXTRA_PLAYLIST_NAME, playlist.name)
        }
        views.setOnClickFillInIntent(R.id.widget_preset_icon, fillInIntent)
        views.setOnClickFillInIntent(R.id.widget_preset_name, fillInIntent)
        views.setOnClickFillInIntent(R.id.widget_preset_item_container, fillInIntent)




        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = playlists[position].id.hashCode().toLong()

    override fun hasStableIds(): Boolean = true
}
