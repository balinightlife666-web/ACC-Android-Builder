package com.ardacore.moshi.business

data class BusinessProfile(
    val businessName: String,
    val category: String,
    val description: String,
    val address: String,
    val hours: String,
)

data class CatalogItem(
    val id: String,
    val ownerId: String,
    val kind: String,
    val title: String,
    val description: String,
    val priceAmount: Long?,
    val currency: String,
    val availability: String,
    val stockQty: Int?,
    val imagePath: String?,
    val isActive: Boolean,
)

data class CatalogImageInput(
    val uri: String,
    val fileName: String,
    val contentType: String,
    val sizeBytes: Long,
)
