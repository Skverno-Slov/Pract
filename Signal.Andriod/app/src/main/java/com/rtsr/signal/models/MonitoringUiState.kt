package com.rtsr.signal.models

data class MonitoringUiState(
    val isAuthorized: Boolean = false,
    val isRefreshing: Boolean = false,
    val devices: List<WebUnit> = emptyList(),
    val selectedDeviceId: String? = null,
    val selectedPeriod: PeriodType = PeriodType.ALL_TIME,
    val isGraphView: Boolean = true,
    val lastUpdateTime: String = ""
)