package com.rtsr.signal.models

data class MainUiState(
    val isAuthorized: Boolean = false,
    val isLoading: Boolean = true,
    val isRefreshing: Boolean = false,
    val devices: List<WebUnit> = emptyList(),
    val selectedDeviceId: String? = null,
    val selectedPeriod: PeriodType = PeriodType.ALL_TIME,
    val isGraphView: Boolean = true,
    val lastUpdateTime: String = ""
)