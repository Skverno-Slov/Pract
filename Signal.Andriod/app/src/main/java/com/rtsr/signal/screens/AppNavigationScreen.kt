package com.rtsr.signal.screens

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import com.rtsr.signal.viewmodel.AppViewModel

@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun AppNavigationScreen(viewModel: AppViewModel) {
    val uiState by viewModel.uiState.collectAsState()

    if (uiState.isAuthorized) {
        MainNavigationContainer(viewModel)
    } else {
        AuthorizationScreen(onLoginClick = { login, password ->
            viewModel.login(login, password)
        })
    }
}