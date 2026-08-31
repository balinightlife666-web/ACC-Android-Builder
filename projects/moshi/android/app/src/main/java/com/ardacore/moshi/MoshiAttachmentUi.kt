package com.ardacore.moshi

import android.graphics.BitmapFactory
import android.media.MediaPlayer
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ardacore.moshi.chat.ChatApi
import com.ardacore.moshi.chat.ChatAttachment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

@Composable
fun MoshiMessageAttachment(
    accessToken: String,
    attachment: ChatAttachment,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current.applicationContext
    val scope = rememberCoroutineScope()
    val api = remember { ChatApi() }
    val ready = attachment.status == "ready" && attachment.downloadPath.isNotBlank()
    val isVoice = attachment.contentType.startsWith("audio/")
    val isImage = attachment.kind == "image" || attachment.contentType.startsWith("image/")
    var loading by remember(attachment.id) { mutableStateOf(false) }
    var error by remember(attachment.id) { mutableStateOf<String?>(null) }
    var imageBytes by remember(attachment.id, attachment.status) { mutableStateOf<ByteArray?>(null) }

    LaunchedEffect(accessToken, attachment.id, attachment.status, attachment.downloadPath) {
        if (ready && isImage && imageBytes == null) {
            imageBytes = runCatching { api.downloadAttachment(accessToken, attachment) }.getOrNull()
        }
    }

    fun openExternally() {
        if (!ready || loading) return
        loading = true
        error = null
        scope.launch {
            try {
                val bytes = imageBytes ?: api.downloadAttachment(accessToken, attachment)
                withContext(Dispatchers.IO) {
                    openDownloadedAttachment(context, attachment, bytes)
                }
            } catch (t: Throwable) {
                error = t.message ?: "Could not open attachment"
            } finally {
                loading = false
            }
        }
    }

    Card(modifier = modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(5.dp),
        ) {
            when {
                isVoice -> InlineVoiceNote(accessToken, api, attachment)
                isImage -> {
                    val bitmap = remember(imageBytes) {
                        imageBytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
                    }
                    if (bitmap != null) {
                        Image(
                            bitmap = bitmap.asImageBitmap(),
                            contentDescription = attachment.fileName,
                            modifier = Modifier.fillMaxWidth().height(180.dp),
                            contentScale = ContentScale.Crop,
                        )
                    } else if (ready) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            CircularProgressIndicator(strokeWidth = 2.dp)
                            Text("Loading photo…", style = MaterialTheme.typography.bodySmall)
                        }
                    }
                    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Photo", fontWeight = FontWeight.SemiBold)
                            Text(attachment.fileName, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        if (ready) TextButton(onClick = ::openExternally, enabled = !loading) { Text("Open") }
                    }
                }
                else -> {
                    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(attachment.fileName, fontWeight = FontWeight.SemiBold)
                            Text(formatAttachmentBytes(attachment.sizeBytes), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        if (ready) {
                            TextButton(onClick = ::openExternally, enabled = !loading) { Text("Open") }
                        } else {
                            Text(attachment.status, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                }
            }
            if (loading) Text("Opening…", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            error?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.error) }
        }
    }
}

@Composable
private fun InlineVoiceNote(accessToken: String, api: ChatApi, attachment: ChatAttachment) {
    val context = LocalContext.current.applicationContext
    val scope = rememberCoroutineScope()
    val ready = attachment.status == "ready" && attachment.downloadPath.isNotBlank()
    var player by remember(attachment.id) { mutableStateOf<MediaPlayer?>(null) }
    var playing by remember(attachment.id) { mutableStateOf(false) }
    var loading by remember(attachment.id) { mutableStateOf(false) }
    var error by remember(attachment.id) { mutableStateOf<String?>(null) }

    DisposableEffect(attachment.id) {
        onDispose {
            runCatching { player?.stop() }
            runCatching { player?.release() }
            player = null
        }
    }

    fun stopPlayback() {
        runCatching { player?.stop() }
        runCatching { player?.release() }
        player = null
        playing = false
    }

    fun play() {
        if (!ready || loading) return
        if (playing) {
            stopPlayback()
            return
        }
        loading = true
        error = null
        scope.launch {
            try {
                val bytes = api.downloadAttachment(accessToken, attachment)
                val file = withContext(Dispatchers.IO) {
                    val dir = File(context.cacheDir, "moshi-voice-playback").apply { mkdirs() }
                    val safe = attachment.fileName.replace(Regex("[^A-Za-z0-9._-]"), "_").take(100).ifBlank { "voice.m4a" }
                    File(dir, "${attachment.id.take(16)}-$safe").apply { writeBytes(bytes) }
                }
                val mediaPlayer = MediaPlayer().apply {
                    setDataSource(file.absolutePath)
                    setOnCompletionListener {
                        runCatching { it.release() }
                        player = null
                        playing = false
                    }
                    prepare()
                    start()
                }
                player = mediaPlayer
                playing = true
            } catch (t: Throwable) {
                stopPlayback()
                error = t.message ?: "Could not play voice note"
            } finally {
                loading = false
            }
        }
    }

    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Column(modifier = Modifier.weight(1f)) {
            Text("Voice note", fontWeight = FontWeight.SemiBold)
            Text(formatAttachmentBytes(attachment.sizeBytes), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            error?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.error) }
        }
        when {
            loading -> CircularProgressIndicator(strokeWidth = 2.dp)
            ready -> TextButton(onClick = ::play) { Text(if (playing) "Stop" else "Play") }
            else -> Text(attachment.status, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

private fun formatAttachmentBytes(size: Long): String = when {
    size >= 1024L * 1024L -> String.format("%.1f MB", size / (1024.0 * 1024.0))
    size >= 1024L -> String.format("%.1f KB", size / 1024.0)
    else -> "$size B"
}
