package com.rtsr.signal.viewmodel

import android.app.Application
import kotlinx.coroutines.flow.update
import android.content.Context
import android.os.Build
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.compose.ui.graphics.Color
import com.rtsr.signal.models.MainUiState
import com.rtsr.signal.models.PeriodType
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
import com.rtsr.signal.dtos.LoginRequest
import com.rtsr.signal.dtos.RefreshRequest
import com.rtsr.signal.models.AppScreen
import com.rtsr.signal.models.ConnectionStatus
import com.rtsr.signal.models.SignalApplication
import com.rtsr.signal.services.NetworkClient
import kotlinx.coroutines.launch
import kotlin.math.abs

@RequiresApi(Build.VERSION_CODES.O)
class AppViewModel(application: Application) : AndroidViewModel(application) {
    private val sharedPrefs = application.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState: StateFlow<MainUiState> = _uiState.asStateFlow()

    val savedAddress = sharedPrefs.getString("api_address", "192.168.59.18") ?: "192.168.59.18"
    val savedPort = sharedPrefs.getString("api_port", "22") ?: "22"

    val api get() = NetworkClient.getApi()

    val tokenManager = SignalApplication.tokenManager

    init {
        loadConnectionSettings(savedAddress, savedPort)

        tryAutoLogin()
    }

    fun updateClient(){
        NetworkClient.init(_uiState.value, tokenManager)
    }

    fun loadDeviceData() {
        val deviceId = _uiState.value.selectedDeviceId ?: return
        val period = _uiState.value.selectedPeriod.name
        val param = _uiState.value.selectedParamIdentifier
        val page = _uiState.value.currentPage
        val pageSize = 8

        viewModelScope.launch {

            try {
                val response = api.getEquipmentLogs(deviceId, period, param, page, pageSize)

                _uiState.update { currentState ->
                    currentState.copy(
                        isLoading = false,
                        isPageLoading = false,
                        logsList = response.logs,
                        availableParams = response.availableIdentifiers,
                        totalCount = response.totalCount
                    )
                }
            } catch (_: Exception) {
                _uiState.update { it.copy(isLoading = false, isPageLoading = false) }
            }
        }
    }

    fun loadAllData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                val remoteDevices = api.getEquipmentList()
                val firstDeviceId = remoteDevices.firstOrNull()?.serialNumber
                val currentSelectedId = _uiState.value.selectedDeviceId
                    ?: sharedPrefs.getString("selected_device_id", firstDeviceId)

                _uiState.update { currentState ->
                    currentState.copy(
                        devices = remoteDevices,
                        selectedDeviceId = currentSelectedId,
                        currentPage = 1
                    )
                }

                if (currentSelectedId != null) {
                    try {
                        val response = api.getEquipmentLogs(
                            currentSelectedId,
                            _uiState.value.selectedPeriod.name,
                            _uiState.value.selectedParamIdentifier,
                            1,
                            8
                        )

                        _uiState.update { currentState ->
                            currentState.copy(
                                isLoading = false,
                                logsList = response.logs,
                                availableParams = response.availableIdentifiers,
                                totalCount = response.totalCount,
                                lastUpdateTime = getCurrentFormattedTime()
                            )
                        }
                    } catch (_: Exception) {
                        _uiState.update { it.copy(isLoading = false, logsList = emptyList(), totalCount = 0) }
                    }
                } else {
                    _uiState.update { it.copy(isLoading = false, logsList = emptyList(), totalCount = 0) }
                }
            } catch (_: Exception) {
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun selectDevice(id: String) {
        sharedPrefs.edit {
            putString("selected_device_id", id)
        }

        _uiState.update { currentState ->
            currentState.copy(
                selectedDeviceId = id,
                currentPage = 1
            )
        }

        loadDeviceData()
    }

    fun refreshData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)

            loadAllData()

            _uiState.value = _uiState.value.copy(
                isRefreshing = false
            )
        }
    }

    private fun tryAutoLogin() {
        val refreshToken = tokenManager.getRefreshToken()
        if (refreshToken.isNullOrBlank()) {
            _uiState.update { it.copy(isAutoLoginChecking = false, isAuthorized = false) }
            return
        }

        viewModelScope.launch {
            try {
                val response = api.refreshTokensAsync(RefreshRequest(refreshToken))
                tokenManager.saveTokens(response.accessToken, response.refreshToken)
                val fullName = listOfNotNull(response.lastName, response.firstName, response.middleName)
                    .joinToString(" ")
                    .ifBlank { " " }

                _uiState.update { it.copy(isAuthorized = true, userFullName = fullName) }
                loadAllData()
            } catch (e: retrofit2.HttpException) {
                tokenManager.clearTokens()
                _uiState.update { it.copy(isAuthorized = false) }
            } catch (e: java.io.IOException) {
                _uiState.update { it.copy(isAuthorized = false) }
            } finally {
                _uiState.update { it.copy(isAutoLoginChecking = false) }
            }
        }
    }

    suspend fun login(loginText: String, passwordText: String) {
        _uiState.update { it.copy(loginErrorMessage = null,isLoginLoading = true) }

        if (loginText.isNotBlank() && passwordText.isNotBlank()) {
            try {
                val response = api.login(LoginRequest(loginText, passwordText), getDeviceName())
                tokenManager.saveTokens(response.accessToken, response.refreshToken)

                val fullName = listOfNotNull(response.lastName, response.firstName, response.middleName)
                    .joinToString(" ")
                    .ifBlank { " " }

                _uiState.update { it.copy(
                    isAuthorized = true,
                    userFullName = fullName,
                    currentScreen = AppScreen.MONITORING
                ) }
                loadAllData()
            } catch (_: retrofit2.HttpException) {
                _uiState.update { it.copy(loginErrorMessage = R.string.error_login_failed) }
            } catch (_: java.io.IOException) {
                _uiState.update { it.copy(loginErrorMessage = R.string.error_api_no_response) }
            } finally {
                _uiState.update { it.copy(isLoginLoading = false) }
            }
        } else {
            _uiState.update { it.copy(loginErrorMessage = R.string.error_empty_fields, isLoginLoading = false) }
        }
    }

    fun loadConnectionSettings(address: String, port: String){
        _uiState.value = _uiState.value.copy(
            apiAddress = address,
            apiPort = port
        )
        updateClient()
    }

    fun saveSettings(address: String, port: String) {
        val isAddressValid = validateAddress(address)
        val isPortValid = validatePort(port)
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
                portErrorResId = null
            )
        }

        Toast.makeText(application, "Настройки сохранены", Toast.LENGTH_SHORT).show()
    }

    fun onSettingsInputChanged(inputAddress: String, inputPort: String) {
        _uiState.update { it.copy(
            apiAddress = inputAddress,
            apiPort = inputPort
        ) }

        if (inputAddress.trim() == savedAddress && inputPort.trim() == savedPort) {
            _uiState.update { it.copy(connectionStatus = ConnectionStatus.SUCCESS) }
        } else {
            _uiState.update { it.copy(connectionStatus = ConnectionStatus.NOT_TESTED) }
        }
    }

    fun checkConnection(address: String, port: String) {
        val isAddressValid = validateAddress(address)
        val isPortValid = validatePort(port)

        if (!isAddressValid || !isPortValid) {
            _uiState.update { it.copy(
                addressErrorResId = if (isAddressValid) null else R.string.error_invalid_address,
                portErrorResId = if (isPortValid) null else R.string.error_invalid_port,
                connectionStatus = ConnectionStatus.FAILED
            ) }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isConnectionChecking = true, apiAddress = address, apiPort = port) }
            try {
                val testUrl = "http://${address.trim()}:${port.trim()}/api/ping"

                val response = api.checkApiHealth(testUrl)

                if (response.service == "SignalTrack.Api") {
                    _uiState.update { it.copy(isConnectionChecking = false, connectionStatus = ConnectionStatus.SUCCESS) }
                } else {
                    _uiState.update { it.copy(isConnectionChecking = false, connectionStatus = ConnectionStatus.FAILED) }
                }
            } catch (_: Exception) {
                _uiState.update { it.copy(isConnectionChecking = false, connectionStatus = ConnectionStatus.FAILED) }
            }
        }
    }

    private fun validateAddress(address: String): Boolean{
        val ipWithDomainRegex = Regex("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\$|^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}\$")
        return address.trim().matches(ipWithDomainRegex)
    }

    private fun validatePort(port: String): Boolean{
        val portInt = port.trim().toIntOrNull()
        return portInt != null && portInt in 1..65535
    }

    fun navigateTo(screen: AppScreen) {
        val isSettingsScreen = screen == AppScreen.SETTINGS
        _uiState.update { currentState ->
            currentState.copy(
                currentScreen = screen,
                addressErrorResId = if (isSettingsScreen) null else currentState.addressErrorResId,
                portErrorResId = if (isSettingsScreen) null else currentState.portErrorResId,
                connectionStatus = if (isSettingsScreen &&
                    currentState.apiAddress == savedAddress &&
                    currentState.apiPort == savedPort) {
                    ConnectionStatus.SUCCESS
                } else {
                    ConnectionStatus.NOT_TESTED
                }
            )
        }
    }

    fun logout() {
        val refreshToken = tokenManager.getRefreshToken()

        viewModelScope.launch {
            try {
                if (!refreshToken.isNullOrBlank()) {
                    NetworkClient.getApi().logoutServer(RefreshRequest(refreshToken))
                }
            } catch (_: Exception) {}
            finally {
                tokenManager.clearTokens()

                sharedPrefs.edit(commit = true) {
                    remove("selected_device_id")
                }

                _uiState.update { currentState ->
                    currentState.copy(
                        isAuthorized = false,
                        selectedDeviceId = null,
                        userFullName = " ",
                        currentPage = 1
                    )
                }
            }
        }
    }

    fun selectPeriod(period: PeriodType) {
        _uiState.update { it.copy(
            selectedPeriod = period,
            currentPage = 1)
        }
        loadDeviceData()
    }

    fun selectParamIdentifier(identifier: String?) {
        _uiState.update {
            it.copy(selectedParamIdentifier = identifier,
                currentPage = 1)
        }
        loadDeviceData()
    }

    fun changePage(page: Int) {
        if (page < 1 || _uiState.value.isPageLoading || _uiState.value.isLoading) return
        _uiState.update { it.copy(currentPage = page, isPageLoading = true) }
        loadDeviceData()
    }

    fun toggleViewMode(isGraph: Boolean) {
        _uiState.update { it.copy(isGraphView = isGraph) }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun getCurrentFormattedTime(): String {
        return LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss"))
    }

    fun getDeviceName(): String {
        val manufacturer = Build.MANUFACTURER
        val model = Build.MODEL
        return if (model.startsWith(manufacturer)) {
            model
        } else {
            "$manufacturer $model"
        }
    }

}