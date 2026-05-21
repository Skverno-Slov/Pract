package com.rtsr.signal.viewmodel

import android.app.Application
import kotlinx.coroutines.flow.update
import android.content.Context
import android.os.Build
import android.widget.Toast
import androidx.annotation.RequiresApi
import com.rtsr.signal.models.MainUiState
import com.rtsr.signal.models.PeriodType
import com.rtsr.signal.models.Statuses
import com.rtsr.signal.models.UnitValues
import com.rtsr.signal.models.WebUnit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import androidx.core.content.edit
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.application
import androidx.lifecycle.viewModelScope
import com.rtsr.signal.R
import com.rtsr.signal.models.AppScreen
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@RequiresApi(Build.VERSION_CODES.O)
class AppViewModel(application: Application) : AndroidViewModel(application) {
    private val sharedPrefs = application.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()

    //TODO: Заменить эту затычку
    private val mockDevices = listOf(
        WebUnit("1a0b9cf", "Мегафон НЗ(1)", "МФ-2000", "2026-05-16 15:30:11", listOf(
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK),
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK),
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK)), Statuses.OK),
        WebUnit("1a0b9ab", "Мегафон НЗ(2)", "МФ-2000(1)", "2026-05-16 15:30:11", listOf(
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK),
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK),
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK)), Statuses.WARN),
        WebUnit("1a0b9gh", "Мегафон НЗ(3)", "МФ-2000", "2026-05-16 15:30:11", listOf(
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK),
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK),
            UnitValues("ebno", "Eb/N0", 9.5, "дБ", Statuses.OK)), Statuses.OK)
    )

    init {

    }

    fun loadInitialData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            //TODO: метод для загрузуи данных из API привязать к состоянию авторизации пользователя
            delay(2000)

            _uiState.value = _uiState.value.copy(
                isLoading = false,
                devices = mockDevices,
                lastUpdateTime = getCurrentFormattedTime()
            )
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun selectDevice(id: String) {
        sharedPrefs.edit { putString("selected_device_id", id) }
        _uiState.update {
            it.copy(
                selectedDeviceId = id,
                lastUpdateTime = getCurrentFormattedTime()
            )
        }
    }

    fun refreshData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)

            //TODO: ЗАГЛУШКА, Запрос в API
            kotlinx.coroutines.delay(2000)

            _uiState.value = _uiState.value.copy(
                isRefreshing = false,
                lastUpdateTime = getCurrentFormattedTime()
            )
        }
    }

    fun login(loginText: String, passwordText: String) {
        if (loginText.isNotBlank() && passwordText.isNotBlank()) {
            //TODO: API, JWT в отдельном методе
            _uiState.value = _uiState.value.copy(isAuthorized = true)
            val savedId = sharedPrefs.getString("selected_device_id", mockDevices.firstOrNull()?.unitId)
            val savedAddress = sharedPrefs.getString("api_address", "192.168.59.18") ?: "192.168.59.18"
            val savedPort = sharedPrefs.getString("api_port", "22") ?: "22"
            if (savedId != null){
                selectDevice(savedId)
            }
            loadConnectionSettings(savedAddress, savedPort)
        }
        //TODO:удалить тестовый вызов
        loadInitialData()
    }

    fun loadConnectionSettings(address: String, port: String){
        _uiState.value = _uiState.value.copy(
            apiAddress = address,
            apiPort = port
        )
    }

    fun saveSettings(address: String, port: String) {
        val ipWithDomainRegex = Regex("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\$|^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}\$")
        val isAddressValid = address.trim().matches(ipWithDomainRegex)
        val portInt = port.trim().toIntOrNull()
        val isPortValid = portInt != null && portInt in 1..65535

        if (!isAddressValid || !isPortValid) {
            _uiState.update { currentState ->
                currentState.copy(
                    addressErrorResId = if (isAddressValid) null else R.string.error_invalid_address,
                    portErrorResId = if (isPortValid) null else R.string.error_invalid_port
                )
            }
            return
        }


        sharedPrefs.edit {
            putString("api_address", address.trim())
                .putString("api_port", port.trim())
        }

        loadConnectionSettings(address, port)

        _uiState.update { currentState ->
            currentState.copy(
                addressErrorResId = null,
                portErrorResId = null,
                currentScreen = AppScreen.MONITORING
            )
        }
    }

    fun clearAddressError() {
        if (_uiState.value.addressErrorResId != null) {
            _uiState.update { it.copy(addressErrorResId = null) }
        }
    }

    fun clearPortError() {
        if (_uiState.value.portErrorResId != null) {
            _uiState.update { it.copy(portErrorResId = null) }
        }
    }

    fun navigateTo(screen: AppScreen) {
        _uiState.update { currentState ->
            currentState.copy(
                currentScreen = screen,
                addressErrorResId = if (screen == AppScreen.SETTINGS) null else currentState.addressErrorResId,
                portErrorResId = if (screen == AppScreen.SETTINGS) null else currentState.portErrorResId
            )
        }
    }

    fun logout() {
        sharedPrefs.edit { remove("selected_device_id") }
        _uiState.value = _uiState.value.copy(
            isAuthorized = false,
            selectedDeviceId = null
        )
    }

    fun selectPeriod(period: PeriodType) {
        _uiState.update { it.copy(selectedPeriod = period) }
    }

    fun toggleViewMode(isGraph: Boolean) {
        _uiState.update { it.copy(isGraphView = isGraph) }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun getCurrentFormattedTime(): String {
        return LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss"))
    }
}