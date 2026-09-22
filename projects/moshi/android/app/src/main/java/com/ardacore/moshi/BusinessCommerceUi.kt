package com.ardacore.moshi

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.ardacore.moshi.auth.AuthController

@Composable
fun BusinessCommerceHubScreen(authController: AuthController, modifier: Modifier = Modifier) {
    MasterBusinessScreen(authController, modifier)
}
