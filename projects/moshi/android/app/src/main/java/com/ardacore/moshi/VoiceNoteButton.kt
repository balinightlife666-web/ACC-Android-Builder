package com.ardacore.moshi

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import java.io.File

@Composable
fun VoiceNoteButton(
    enabled: Boolean,
    onReady: (File) -> Unit,
    onError: (String) -> Unit,
) {
    val context = LocalContext.current
    val recorder = remember { VoiceNoteRecorder(context.applicationContext) }
    var recording by remember { mutableStateOf(false) }

    fun startRecording() {
        try {
            recorder.start()
            recording = true
        } catch (t: Throwable) {
            recorder.cancel()
            recording = false
            onError(t.message ?: "Could not start voice recording")
        }
    }

    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) startRecording() else onError("Microphone permission is required for voice notes")
    }

    DisposableEffect(recorder) {
        onDispose { recorder.cancel() }
    }

    OutlinedButton(
        onClick = {
            if (recording) {
                try {
                    val file = recorder.stop()
                    recording = false
                    onReady(file)
                } catch (t: Throwable) {
                    recorder.cancel()
                    recording = false
                    onError(t.message ?: "Could not save voice note")
                }
            } else {
                val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
                if (granted) startRecording() else permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
            }
        },
        enabled = enabled || recording,
    ) {
        Text(if (recording) "Stop" else "Voice")
    }
}
