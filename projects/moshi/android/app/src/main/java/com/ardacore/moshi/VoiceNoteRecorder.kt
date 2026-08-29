package com.ardacore.moshi

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import java.io.File

class VoiceNoteRecorder(context: Context) {
    private val appContext = context.applicationContext
    private var recorder: MediaRecorder? = null
    private var outputFile: File? = null

    val isRecording: Boolean
        get() = recorder != null

    fun start(): File {
        check(recorder == null) { "Voice recording is already active" }
        val directory = File(appContext.cacheDir, "moshi-voice").apply { mkdirs() }
        val file = File(directory, "voice-${System.currentTimeMillis()}.m4a")
        val mediaRecorder = newRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioEncodingBitRate(64_000)
            setAudioSamplingRate(44_100)
            setMaxDuration(5 * 60 * 1000)
            setOutputFile(file.absolutePath)
            prepare()
            start()
        }
        outputFile = file
        recorder = mediaRecorder
        return file
    }

    fun stop(): File {
        val active = recorder ?: error("Voice recording is not active")
        val file = outputFile ?: error("Voice recording file is missing")
        try {
            active.stop()
        } catch (error: RuntimeException) {
            file.delete()
            throw IllegalStateException("Voice note was too short to save", error)
        } finally {
            active.reset()
            active.release()
            recorder = null
            outputFile = null
        }
        if (!file.isFile || file.length() <= 0L) {
            file.delete()
            error("Voice note is empty")
        }
        return file
    }

    fun cancel() {
        val active = recorder
        val file = outputFile
        if (active != null) {
            runCatching { active.stop() }
            runCatching { active.reset() }
            runCatching { active.release() }
        }
        recorder = null
        outputFile = null
        file?.delete()
    }

    @Suppress("DEPRECATION")
    private fun newRecorder(): MediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        MediaRecorder(appContext)
    } else {
        MediaRecorder()
    }
}
