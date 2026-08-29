package com.ardacore.moshi.chat.local

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Index
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Entity(tableName = "cached_conversations")
data class CachedConversationEntity(
    @PrimaryKey val id: String,
    val payloadJson: String,
    val sortOrder: Int,
)

@Entity(
    tableName = "cached_messages",
    indices = [
        Index(value = ["conversationId"]),
        Index(value = ["clientMessageId"], unique = true),
    ],
)
data class CachedMessageEntity(
    @PrimaryKey val id: String,
    val conversationId: String,
    val clientMessageId: String,
    val createdAt: String,
    val payloadJson: String,
)

@Entity(
    tableName = "outbox_messages",
    indices = [Index(value = ["conversationId"])],
)
data class OutboxMessageEntity(
    @PrimaryKey val clientMessageId: String,
    val conversationId: String,
    val body: String,
    val replyToId: String?,
    val createdAtEpochMs: Long,
    val attemptCount: Int = 0,
    val lastError: String? = null,
    val attachmentUri: String? = null,
    val attachmentKind: String? = null,
    val attachmentFileName: String? = null,
    val attachmentContentType: String? = null,
    val attachmentSizeBytes: Long? = null,
    val uploadedAttachmentId: String? = null,
)

@Dao
interface ChatDao {
    @Query("SELECT * FROM cached_conversations ORDER BY sortOrder ASC")
    suspend fun conversations(): List<CachedConversationEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertConversations(items: List<CachedConversationEntity>)

    @Query("DELETE FROM cached_conversations")
    suspend fun clearConversations()

    @Query("SELECT * FROM cached_messages WHERE conversationId = :conversationId ORDER BY createdAt ASC")
    suspend fun messages(conversationId: String): List<CachedMessageEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertMessages(items: List<CachedMessageEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertMessage(item: CachedMessageEntity)

    @Query("DELETE FROM cached_messages WHERE clientMessageId = :clientMessageId")
    suspend fun deleteMessageByClientId(clientMessageId: String)

    @Query("SELECT * FROM outbox_messages ORDER BY createdAtEpochMs ASC")
    suspend fun outbox(): List<OutboxMessageEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun enqueue(item: OutboxMessageEntity)

    @Query("DELETE FROM outbox_messages WHERE clientMessageId = :clientMessageId")
    suspend fun removeOutbox(clientMessageId: String)

    @Query("UPDATE outbox_messages SET attemptCount = attemptCount + 1, lastError = :error WHERE clientMessageId = :clientMessageId")
    suspend fun markAttempt(clientMessageId: String, error: String)

    @Query("UPDATE outbox_messages SET uploadedAttachmentId = :attachmentId, lastError = NULL WHERE clientMessageId = :clientMessageId")
    suspend fun markAttachmentUploaded(clientMessageId: String, attachmentId: String)
}

@Database(
    entities = [CachedConversationEntity::class, CachedMessageEntity::class, OutboxMessageEntity::class],
    version = 2,
    exportSchema = false,
)
abstract class MoshiChatDatabase : RoomDatabase() {
    abstract fun chatDao(): ChatDao

    companion object {
        @Volatile private var instance: MoshiChatDatabase? = null

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE outbox_messages ADD COLUMN attachmentUri TEXT")
                db.execSQL("ALTER TABLE outbox_messages ADD COLUMN attachmentKind TEXT")
                db.execSQL("ALTER TABLE outbox_messages ADD COLUMN attachmentFileName TEXT")
                db.execSQL("ALTER TABLE outbox_messages ADD COLUMN attachmentContentType TEXT")
                db.execSQL("ALTER TABLE outbox_messages ADD COLUMN attachmentSizeBytes INTEGER")
                db.execSQL("ALTER TABLE outbox_messages ADD COLUMN uploadedAttachmentId TEXT")
            }
        }

        fun get(context: Context): MoshiChatDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(
                context.applicationContext,
                MoshiChatDatabase::class.java,
                "moshi-chat.db",
            ).addMigrations(MIGRATION_1_2).build().also { instance = it }
        }
    }
}
