package com.tuthanika.rolify.plus.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.tuthanika.rolify.plus.R

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
    private var playingPaths: List<String> = emptyList() // THÊM BIẾN NÀY

    override fun onCreate() {
        // Nothing heavy
    }

    override fun onDataSetChanged() {
        // Fetch from SharedPreferences
        audios = FlutterDataHelper.getAudios(context)

        // ĐỌC TRẠNG THÁI PLAYING 1 LẦN DUY NHẤT Ở ĐÂY THAY VÌ TRONG getViewAt
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val playingCsv = prefs.getString("flutter.widget_playing_paths_csv", "") ?: ""
        playingPaths = playingCsv.split(",,")
    }

    override fun onDestroy() {
        audios = emptyList()
    }

    override fun getCount(): Int = audios.size

    override fun getViewAt(position: Int): RemoteViews {
        val audio = audios[position]
        val views = RemoteViews(context.packageName, R.layout.widget_playlist_item)

        views.setTextViewText(R.id.widget_playlist_name, audio.name)

        // XÓA ĐOẠN ĐỌC SHAREDPREFERENCES Ở ĐÂY VÀ DÙNG BIẾN ĐÃ LƯU
        val isPlaying = playingPaths.contains(audio.path)

        val buttonIcon = if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_baseline_add_24
        views.setImageViewResource(R.id.widget_playlist_button, buttonIcon)

        if (isPlaying || audio.isActive) {
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
        views.setOnClickFillInIntent(R.id.widget_playlist_item_container, fillInIntent)



        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = audios[position].path.hashCode().toLong()

    override fun hasStableIds(): Boolean = true
}
