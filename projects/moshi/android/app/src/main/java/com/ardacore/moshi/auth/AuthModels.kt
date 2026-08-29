package com.ardacore.moshi.auth

data class MoshiUser(
    val id: String,
    val username: String,
    val displayName: String,
    val businessMode: Boolean,
)

data class AuthSession(
    val user: MoshiUser,
    val accessToken: String,
    val refreshToken: String,
)

class ApiException(message: String, val statusCode: Int) : Exception(message)
