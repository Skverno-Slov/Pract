package com.rtsr.signal.models

data class MainUiState(
    val isAuthorized: Boolean = false,
    val isLoading: Boolean = true,
    val currentScreen: AppScreen = AppScreen.MONITORING,
    val isRefreshing: Boolean = false,
    val devices: List<WebUnit> = emptyList(),
    val selectedDeviceId: String? = null,
    val selectedPeriod: PeriodType = PeriodType.ALL_TIME,
    val isGraphView: Boolean = true,
    val lastUpdateTime: String = "",
    val apiAddress: String = "192.168.59.18",
    val apiPort: String = "22",
    val addressErrorResId: Int? = null,
    val portErrorResId: Int? = null
)