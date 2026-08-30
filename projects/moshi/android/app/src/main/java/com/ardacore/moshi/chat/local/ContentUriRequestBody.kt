package com.ardacore.moshi.chat.local

import android.content.Context
import android.net.Uri
import okhttp3.MediaType
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody
import okio.BufferedSink
import java.io.IOException

class ContentUriRequestBody(
    context: Context,
    private val uriText: String,
    contentType: String,
    private val expectedSize: Long,
) : RequestBody() {
    private val appContext = context.applicationContext
    private val mediaType = contentType.toMediaType()

    override fun contentType(): MediaType = mediaType

    override fun contentLength(): Long = expectedSize

    override fun writeTo(sink: BufferedSink) {
        val uri = Uri.parse(uriText)
        var total = 0L
        appContext.contentResolver.openInputStream(uri)?.use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                total += count
                if (total > expectedSize) throw IOException("Attachment changed after it was queued")
                sink.write(buffer, 0, count)
            }
        } ?: throw IOException("Could not reopen queued attachment")
        if (total != expectedSize) throw IOException("Attachment changed after it was queued")
    }
}
