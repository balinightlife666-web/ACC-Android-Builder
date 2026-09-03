package com.ardacore.moshi.chat.local

import android.content.Context

class ChatListStateStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("moshi_chat_list_state", Context.MODE_PRIVATE)

    fun archived(): Set<String> = prefs.getStringSet(KEY_ARCHIVED, emptySet()).orEmpty().toSet()

    fun hidden(): Set<String> = prefs.getStringSet(KEY_HIDDEN, emptySet()).orEmpty().toSet()

    fun pinned(): Set<String> = prefs.getStringSet(KEY_PINNED, emptySet()).orEmpty().toSet()

    fun folderAssignments(): Map<String, String> = prefs.getStringSet(KEY_FOLDERS, emptySet())
        .orEmpty()
        .mapNotNull { encoded ->
            val separator = encoded.indexOf(SEPARATOR)
            if (separator <= 0 || separator >= encoded.lastIndex) null
            else encoded.substring(0, separator) to encoded.substring(separator + 1)
        }
        .toMap()

    fun folderNames(): List<String> = folderAssignments().values.distinct().sortedBy { it.lowercase() }

    fun setArchived(conversationId: String, archived: Boolean) {
        writeSet(KEY_ARCHIVED, this.archived().toggle(conversationId, archived))
        if (archived) setHidden(conversationId, false)
    }

    fun setHidden(conversationId: String, hidden: Boolean) {
        writeSet(KEY_HIDDEN, this.hidden().toggle(conversationId, hidden))
        if (hidden) setArchived(conversationId, false)
    }

    fun setPinned(conversationId: String, pinned: Boolean) {
        writeSet(KEY_PINNED, this.pinned().toggle(conversationId, pinned))
    }

    fun moveToFolder(conversationId: String, folder: String?) {
        val cleaned = folder?.trim()?.take(32).orEmpty()
        val assignments = folderAssignments().toMutableMap()
        if (cleaned.isBlank()) assignments.remove(conversationId) else assignments[conversationId] = cleaned
        writeSet(KEY_FOLDERS, assignments.mapTo(mutableSetOf()) { "${it.key}$SEPARATOR${it.value}" })
    }

    private fun Set<String>.toggle(value: String, enabled: Boolean): Set<String> =
        toMutableSet().apply { if (enabled) add(value) else remove(value) }

    private fun writeSet(key: String, values: Set<String>) {
        prefs.edit().putStringSet(key, values.toSet()).apply()
    }

    private companion object {
        const val KEY_ARCHIVED = "archived"
        const val KEY_HIDDEN = "hidden"
        const val KEY_PINNED = "pinned"
        const val KEY_FOLDERS = "folders"
        const val SEPARATOR = '\u001F'
    }
}
