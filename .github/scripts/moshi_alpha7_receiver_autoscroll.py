from pathlib import Path

chat = Path("projects/moshi/android/app/src/main/java/com/ardacore/moshi/ChatUi.kt")
text = chat.read_text()
old = """    val latestMessageId = controller.messages.lastOrNull()?.id
    LaunchedEffect(conversation.id, latestMessageId) {
        if (controller.messages.isNotEmpty()) {
            messageListState.animateScrollToItem(controller.messages.lastIndex)
        }
    }
"""
new = """    val messageCount = controller.messages.size
    val latestMessage = controller.messages.lastOrNull()
    val latestMessageRevision = latestMessage?.let { it.id + ":" + it.createdAt + ":" + it.state }
    LaunchedEffect(conversation.id, messageCount, latestMessageRevision) {
        if (messageCount > 0) {
            androidx.compose.runtime.withFrameNanos { }
            messageListState.scrollToItem(messageCount - 1)
        }
    }
"""
if old not in text:
    raise SystemExit("expected autoscroll block not found")
chat.write_text(text.replace(old, new, 1))

gradle = Path("projects/moshi/android/app/build.gradle.kts")
g = gradle.read_text()
if "versionCode = 8" not in g or 'versionName = "0.4.0-alpha.6"' not in g:
    raise SystemExit("expected Alpha.6 version block not found")
g = g.replace("versionCode = 8", "versionCode = 9", 1)
g = g.replace('versionName = "0.4.0-alpha.6"', 'versionName = "0.4.0-alpha.7"', 1)
gradle.write_text(g)
