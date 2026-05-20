package com.rtsr.signal.viewmodel

import android.app.Application
import kotlinx.coroutines.flow.update
import android.content.Context
import android.os.Build
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
import androidx.lifecycle.viewModelScope
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
            if (savedId != null){
                selectDevice(savedId)
            }
        }
        //TODO:удалить тестовый вызов
        loadInitialData()
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