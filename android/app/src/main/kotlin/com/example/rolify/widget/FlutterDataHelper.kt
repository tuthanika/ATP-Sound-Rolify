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
        val activePaths = getActivePaths(context)

        val results = mutableListOf<RolifyAudio>()
        try {
            val jsonArray = JSONArray(audiosJsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val path = obj.optString("path", "")
                results.add(
                    RolifyAudio(
                        name = obj.optString("name", "Unknown Audio"),
                        path = path,
                        image = obj.optString("image", ""),
                        loopMode = obj.optBoolean("loopMode", true),
                        isActive = activePaths.contains(path)
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
        val playlistsJsonStr = prefs.getString("flutter.playlist", null) ?: return emptyList()
        val activeIds = getActivePlaylistIds(context)

        val results = mutableListOf<RolifyPlaylist>()
        try {
            val jsonArray = JSONArray(playlistsJsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val id = obj.optString("id", i.toString())
                
                // Audios in playlist are encoded as a JSON string in Dart
                val audiosStr = obj.optString("audios", null)
                val pAudios = mutableListOf<RolifyAudio>()
                if (audiosStr != null && audiosStr.isNotEmpty()) {
                    try {
                        val audiosArray = JSONArray(audiosStr)
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
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                
                results.add(
                    RolifyPlaylist(
                        id = id,
                        name = obj.optString("name", "Unknown Playlist"),
                        isActive = activeIds.contains(id),
                        audios = pAudios
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return results
    }

    private fun getActivePaths(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val stateJson = prefs.getString("flutter.widget_state", null) ?: return emptySet()
        return try {
            val obj = JSONObject(stateJson)
            val arr = obj.optJSONArray("playingPaths") ?: return emptySet()
            val set = mutableSetOf<String>()
            for (i in 0 until arr.length()) set.add(arr.getString(i))
            set
        } catch (e: Exception) {
            emptySet()
        }
    }

    private fun getActivePlaylistIds(context: Context): Set<String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val stateJson = prefs.getString("flutter.widget_state", null) ?: return emptySet()
        return try {
            val obj = JSONObject(stateJson)
            val arr = obj.optJSONArray("activePlaylistIds") ?: return emptySet()
            val set = mutableSetOf<String>()
            for (i in 0 until arr.length()) set.add(arr.getString(i))
            set
        } catch (e: Exception) {
            emptySet()
        }
    }
    
    fun getActiveCounts(context: Context): Pair<Int, Int> {
        val audios = getAudios(context)
        val activeAudios = audios.count { it.isActive }
        val playlists = getPlaylists(context)
        val activePlaylists = playlists.count { it.isActive }
        return Pair(activeAudios, activePlaylists)
    }

    fun isPlaying(context: Context): Boolean {
        return getActivePaths(context).isNotEmpty()
    }
}
