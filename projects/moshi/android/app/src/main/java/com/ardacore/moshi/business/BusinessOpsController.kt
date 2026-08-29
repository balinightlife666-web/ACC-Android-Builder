package com.ardacore.moshi.business

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.ardacore.moshi.auth.AuthSession

class BusinessOpsController(
    private val session: AuthSession,
    private val api: BusinessOpsApi = BusinessOpsApi(),
) {
    var orders: List<BusinessOrder> by mutableStateOf(emptyList())
        private set
    var quickReplies: List<QuickReplyItem> by mutableStateOf(emptyList())
        private set
    var labels: List<CustomerLabel> by mutableStateOf(emptyList())
        private set
    var selectedCustomerLabels: List<CustomerLabel> by mutableStateOf(emptyList())
        private set
    var busy: Boolean by mutableStateOf(false)
        private set
    var error: String? by mutableStateOf(null)
        private set

    suspend fun loadAll() = runBusy {
        orders = api.orders(session.accessToken)
        quickReplies = api.quickReplies(session.accessToken)
        labels = api.labels(session.accessToken)
    }

    suspend fun refreshOrders() = runBusy { orders = api.orders(session.accessToken) }

    suspend fun setOrderStatus(order: BusinessOrder, status: String) = runBusy {
        val updated = api.updateOrderStatus(session.accessToken, order.id, status)
        orders = orders.map { if (it.id == updated.id) updated else it }
    }

    fun allowedStatusActions(order: BusinessOrder): List<String> {
        val isBuyer = order.buyerId == session.user.id
        val isSeller = order.sellerId == session.user.id
        return when {
            isBuyer && order.status == "draft" -> listOf("awaiting_confirmation", "cancelled")
            isBuyer && order.status == "awaiting_confirmation" -> listOf("cancelled")
            isSeller && order.status in setOf("draft", "awaiting_confirmation") -> listOf("confirmed", "cancelled")
            isSeller && order.status == "confirmed" -> listOf("processing", "cancelled")
            isSeller && order.status == "processing" -> listOf("completed", "cancelled")
            else -> emptyList()
        }
    }

    suspend fun createQuickReply(shortcut: String, title: String, body: String): Boolean = runBusyResult {
        api.createQuickReply(session.accessToken, shortcut, title, body)
        quickReplies = api.quickReplies(session.accessToken)
        true
    } ?: false

    suspend fun deleteQuickReply(item: QuickReplyItem) = runBusy {
        api.deleteQuickReply(session.accessToken, item.id)
        quickReplies = api.quickReplies(session.accessToken)
    }

    suspend fun createLabel(name: String): Boolean = runBusyResult {
        api.createLabel(session.accessToken, name)
        labels = api.labels(session.accessToken)
        true
    } ?: false

    suspend fun deleteLabel(item: CustomerLabel) = runBusy {
        api.deleteLabel(session.accessToken, item.id)
        labels = api.labels(session.accessToken)
        selectedCustomerLabels = selectedCustomerLabels.filterNot { it.id == item.id }
    }

    suspend fun loadCustomer(username: String) = runBusy {
        selectedCustomerLabels = api.customerLabels(session.accessToken, username)
    }

    suspend fun toggleCustomerLabel(username: String, label: CustomerLabel) = runBusy {
        selectedCustomerLabels = if (selectedCustomerLabels.any { it.id == label.id }) {
            api.removeLabel(session.accessToken, username, label.id)
        } else {
            api.assignLabel(session.accessToken, username, label.id)
        }
    }

    fun clearError() { error = null }

    private suspend fun runBusy(block: suspend () -> Unit) {
        if (busy) return
        busy = true
        error = null
        try { block() } catch (t: Throwable) { error = t.message ?: "MOSHI business operation failed" } finally { busy = false }
    }

    private suspend fun <T> runBusyResult(block: suspend () -> T): T? {
        if (busy) return null
        busy = true
        error = null
        return try { block() } catch (t: Throwable) { error = t.message ?: "MOSHI business operation failed"; null } finally { busy = false }
    }
}
