package com.ardacore.moshi

import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import com.ardacore.moshi.chat.ChatAttachment
import java.io.File

fun openDownloadedAttachment(context: Context, attachment: ChatAttachment, bytes: ByteArray) {
    val directory = File(context.cacheDir, "moshi-attachments").apply { mkdirs() }
    val safeName = attachment.fileName
        .replace(Regex("[^A-Za-z0-9._ -]"), "_")
        .take(120)
        .ifBlank { "attachment" }
    val file = File(directory, "${attachment.id.take(12)}-$safeName")
    file.writeBytes(bytes)
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
    val intent = Intent(Intent.ACTION_VIEW).apply {
        setDataAndType(uri, attachment.contentType)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    val chooser = Intent.createChooser(intent, "Open ${attachment.fileName}").apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    context.startActivity(chooser)
}
