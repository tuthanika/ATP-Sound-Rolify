package com.example.rolify.widget

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

data class RolifyAudio(
    val name: String,
    val path: String,
    val image: String,
    val loopMode: Boolean,
    var isActive: Boolean = false
)

data class RolifyPlaylist(
    val id: String,
    val name: String,
    var isActive: Boolean = false,
    val audios: List<RolifyAudio>
)

object FlutterDataHelper {
    private const val PREFS_NAME = "FlutterSharedPreferences"

    fun getAudios(context: Context): List<RolifyAudio> {
        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val audiosJsonStr = prefs.getString("flutter.audios", null) ?: return emptyList()

        val results = mutableListOf<RolifyAudio>()
        try {
            val jsonArray = JSONArray(audiosJsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                results.add(
                    RolifyAudio(
                        name = obj.optString("name", "Unknown Audio"),
                        path = obj.optString("path", ""),
                        image = obj.optString("image", ""),
                        loopMode = obj.optBoolean("loopMode", true)
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return results
    }

    fun getPlaylists(context: Context): List<RolifyPlaylist> {
        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val playlistsJsonStr = prefs.getString("flutter.playlists", null) ?: return emptyList()

        val results = mutableListOf<RolifyPlaylist>()
        try {
            val jsonArray = JSONArray(playlistsJsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                
                val audiosArray = obj.optJSONArray("audios")
                val pAudios = mutableListOf<RolifyAudio>()
                if (audiosArray != null) {
                    for (j in 0 until audiosArray.length()) {
                        val aObj = audiosArray.getJSONObject(j)
                        pAudios.add(
                            RolifyAudio(
                                name = aObj.optString("name", "Unknown Audio"),
                                path = aObj.optString("path", ""),
                                image = aObj.optString("image", ""),
                                loopMode = aObj.optBoolean("loopMode", true)
                            )
                        )
                    }
                }
                
                results.add(
                    RolifyPlaylist(
                        id = obj.optString("id", i.toString()),
                        name = obj.optString("name", "Unknown Playlist"),
                        audios = pAudios
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return results
    }
}
