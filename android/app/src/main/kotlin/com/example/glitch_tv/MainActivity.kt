package com.example.glitch_tv

import android.content.ContentUris
import android.content.ContentValues
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.glitch_tv/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToPodcasts" -> {
                    val tempPath = call.argument<String>("tempPath")
                    val fileName = call.argument<String>("fileName")
                    if (tempPath != null && fileName != null) {
                        try {
                            val savedPath = saveFileToPodcasts(tempPath, fileName)
                            result.success(savedPath)
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing arguments", null)
                    }
                }
                "deleteFromPodcasts" -> {
                    val fileName = call.argument<String>("fileName")
                    if (fileName != null) {
                        try {
                            val deleted = deleteFileFromPodcasts(fileName)
                            result.success(deleted)
                        } catch (e: Exception) {
                            result.error("DELETE_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "FileName was null", null)
                    }
                }
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        MediaScannerConnection.scanFile(context, arrayOf(path), null) { _, uri ->
                            result.success(uri?.toString())
                        }
                    } else {
                        result.error("INVALID_PATH", "Path was null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveFileToPodcasts(tempPath: String, fileName: String): String {
        val srcFile = File(tempPath)
        val mimeType = when {
            fileName.endsWith(".m4a", true) -> "audio/mp4"
            fileName.endsWith(".aac", true) -> "audio/aac"
            fileName.endsWith(".wav", true) -> "audio/wav"
            else -> "audio/mpeg"
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = context.contentResolver

            // Delete any previous item with the same name if exists in MediaStore
            try {
                val projection = arrayOf(MediaStore.Audio.Media._ID)
                val selection = "${MediaStore.Audio.Media.DISPLAY_NAME} = ?"
                val selectionArgs = arrayOf(fileName)
                resolver.query(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    projection,
                    selection,
                    selectionArgs,
                    null
                )?.use { cursor ->
                    while (cursor.moveToNext()) {
                        val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                        val deleteUri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
                        resolver.delete(deleteUri, null, null)
                    }
                }
            } catch (_: Exception) {}

            val contentValues = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Audio.Media.TITLE, fileName.substringBeforeLast('.'))
                put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
                put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_PODCASTS)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw IllegalStateException("Failed to insert MediaStore entry")

            resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(srcFile).use { input ->
                    input.copyTo(out)
                }
            }

            contentValues.clear()
            contentValues.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(uri, contentValues, null, null)

            val directPath = "/storage/emulated/0/Podcasts/$fileName"
            MediaScannerConnection.scanFile(context, arrayOf(directPath), arrayOf(mimeType), null)
            return directPath
        } else {
            val podcastsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PODCASTS)
            if (!podcastsDir.exists()) {
                podcastsDir.mkdirs()
            }
            val destFile = File(podcastsDir, fileName)
            srcFile.copyTo(destFile, overwrite = true)
            MediaScannerConnection.scanFile(context, arrayOf(destFile.absolutePath), arrayOf(mimeType), null)
            return destFile.absolutePath
        }
    }

    private fun deleteFileFromPodcasts(fileName: String): Boolean {
        var deleted = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val resolver = context.contentResolver
                val projection = arrayOf(MediaStore.Audio.Media._ID)
                val selection = "${MediaStore.Audio.Media.DISPLAY_NAME} = ?"
                val selectionArgs = arrayOf(fileName)
                resolver.query(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    projection,
                    selection,
                    selectionArgs,
                    null
                )?.use { cursor ->
                    while (cursor.moveToNext()) {
                        val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                        val deleteUri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
                        resolver.delete(deleteUri, null, null)
                        deleted = true
                    }
                }
            } catch (_: Exception) {}
        }
        val directFile = File("/storage/emulated/0/Podcasts/$fileName")
        if (directFile.exists()) {
            if (directFile.delete()) {
                deleted = true
            }
        }
        return deleted
    }
}
