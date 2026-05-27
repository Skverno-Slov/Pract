package com.rtsr.signal.screens

import android.icu.util.TimeZone
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.rememberTransformableState
import androidx.compose.foundation.gestures.transformable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MaterialTheme.colorScheme
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.NavigationDrawerItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.rtsr.signal.R
import com.rtsr.signal.dtos.ReadingLogDto
import com.rtsr.signal.models.AppScreen
import com.rtsr.signal.models.MainUiState
import com.rtsr.signal.models.PeriodType
import com.rtsr.signal.viewmodel.AppViewModel
import kotlinx.coroutines.launch
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.collections.map
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.time.ExperimentalTime
import kotlin.time.Instant
import kotlin.time.toJavaInstant
import android.graphics.Color as AndroidColor

@RequiresApi(Build.VERSION_CODES.O)
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun MainNavigationContainer(vm: AppViewModel) {
    val uiState by vm.uiState.collectAsState()
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()

    val pagerState = rememberPagerState(pageCount = { 2 })

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet {
                Spacer(modifier = Modifier.height(16.dp))
                NavigationDrawerItem(
                    icon = { Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text(stringResource(R.string.menu_monitoring)) },
                    selected = uiState.currentScreen == AppScreen.MONITORING,
                    onClick = {
                        vm.navigateTo(AppScreen.MONITORING)
                        scope.launch { drawerState.close() }
                    }
                )
                NavigationDrawerItem(
                    icon = { Icon(Icons.Default.Settings, contentDescription = null) },
                    label = { Text(stringResource(R.string.menu_settings)) },
                    selected = uiState.currentScreen == AppScreen.SETTINGS,
                    onClick = {
                        vm.navigateTo(AppScreen.SETTINGS)
                        scope.launch { drawerState.close() }
                    }
                )
                NavigationDrawerItem(
                    icon = { Icon(Icons.Default.Info, contentDescription = null) },
                    label = { Text(stringResource(R.string.menu_report_issue)) },
                    selected = false,
                    onClick = {
                        vm.navigateTo(AppScreen.CONTACT)
                        scope.launch { drawerState.close() }
                    }
                )
                NavigationDrawerItem(
                    icon = { Icon(Icons.Default.ExitToApp, contentDescription = null) },
                    label = { Text(stringResource(R.string.menu_logout)) },
                    selected = false,
                    onClick = { vm.logout() }
                )
            }
        }
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = {},
                    navigationIcon = {
                        IconButton(onClick = { scope.launch { drawerState.open() } }) {
                            Icon(Icons.Default.Menu, contentDescription = "", tint = MaterialTheme.colorScheme.onPrimary)
                        }
                    },
                    actions = {
                        Text(
                            text = uiState.userFullName,
                            modifier = Modifier.padding(end = 16.dp),
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant,
                        navigationIconContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                        actionIconContentColor = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                )
            },
            bottomBar = {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .windowInsetsPadding(WindowInsets.navigationBars)
                        .padding(8.dp),
                    contentAlignment = Alignment.CenterStart
                ) {
                    Text(
                        text = stringResource(R.string.footer_copyright),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }
        ) { paddingValues ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                when (uiState.currentScreen) {
                    AppScreen.SETTINGS -> {
                        SettingsScreen(
                            uiState = vm.uiState.collectAsState().value,
                            onSaveClick = { address, port -> vm.saveSettings(address, port) },
                            onFieldsValueChange = { address, port -> vm.onSettingsInputChanged(address, port) },
                            onCheckConnectionClick = { address, port -> vm.checkConnection(address, port) },
                            onBack = { screen -> vm.navigateTo(screen) },
                            screen = AppScreen.MONITORING
                        )
                    }
                    AppScreen.CONTACT ->{
                        ContactScreen()
                    }
                    AppScreen.MONITORING -> {
                        when {
                            uiState.isLoading -> {
                                LoadingStateScreen()
                            }

                            uiState.devices.isEmpty() -> {
                                EmptyStateScreen({ vm.loadDeviceData() })
                            }

                            else -> {
                                PullToRefreshBox(
                                    isRefreshing = uiState.isRefreshing,
                                    onRefresh = { vm.refreshData() },
                                    modifier = Modifier.fillMaxSize()
                                ) {
                                    HorizontalPager(
                                        state = pagerState,
                                        modifier = Modifier
                                            .fillMaxSize()
                                    ) { page ->
                                        when (page) {
                                            0 -> DashboardScreen(
                                                uiState = vm.uiState.collectAsState().value,
                                                onPeriodSelected = { period -> vm.selectPeriod(period) },
                                                onViewModeChanged = { isGraph -> vm.toggleViewMode(isGraph) },
                                                onParamSelected = { paramId -> vm.selectParamIdentifier(paramId) },
                                                onPageSelected = { pageNum -> vm.changePage(pageNum) }
                                            )

                                            1 -> DeviceListScreen(
                                                uiState = uiState,
                                                onDeviceSelected = { deviceId ->
                                                    vm.selectDevice(deviceId)
                                                    scope.launch { pagerState.animateScrollToPage(0) }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    uiState: MainUiState,
    onPeriodSelected: (PeriodType) -> Unit,
    onViewModeChanged: (Boolean) -> Unit,
    onParamSelected: (String?) -> Unit,
    onPageSelected: (Int) -> Unit // Новый колбэк переключения страниц
) {
    val currentDevice = uiState.devices.find { it.serialNumber == uiState.selectedDeviceId }
    val colorScheme = MaterialTheme.colorScheme

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        // Шапка и фильтры параметров
        item {
            Spacer(modifier = Modifier.height(16.dp))
            Text(text = stringResource(R.string.data_actual_at, uiState.lastUpdateTime), style = MaterialTheme.typography.bodySmall, color = Color.Gray)
            Spacer(modifier = Modifier.height(4.dp))
            Text(text = currentDevice?.name ?: "—", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(12.dp))

            Text(text = "Фильтр параметра:", style = MaterialTheme.typography.labelMedium, color = Color.Gray)
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                item { FilterChip(selected = uiState.selectedParamIdentifier == null, onClick = { onParamSelected(null) }, label = { Text("Все") }) }
                items(uiState.availableParams) { paramId ->
                    FilterChip(selected = uiState.selectedParamIdentifier == paramId, onClick = { onParamSelected(paramId) }, label = { Text(paramId) }) }
            }
            Spacer(modifier = Modifier.height(12.dp))
        }

        // Логика переключения График / Таблица
        if (uiState.isGraphView) {
            item {
                Box(
                    modifier = Modifier.fillMaxWidth().height(250.dp).background(colorScheme.secondaryContainer.copy(alpha = 0.4f)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "Компонент будущих графиков параметров", style = MaterialTheme.typography.titleMedium)
                }
            }
        } else {
            // --- Тонкий аккуратный индикатор загрузки над таблицей ---
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp) // Фиксированная высота, чтобы контент не прыгал
                ) {
                    if (uiState.isPageLoading) {
                        LinearProgressIndicator(
                            modifier = Modifier.fillMaxWidth(),
                            color = colorScheme.primary,
                            trackColor = Color.Transparent
                        )
                    }
                }
            }

            // Шапка таблицы
            item {
                Row(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(text = "Показание", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, modifier = Modifier.weight(2f))
                    Text(text = "Значение", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1.5f), textAlign = TextAlign.End)
                    Text(text = "Дата", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, modifier = Modifier.weight(2f), textAlign = TextAlign.End)
                }
                HorizontalDivider(color = colorScheme.outlineVariant)
            }

            // Вывод строк таблицы с мягким эффектом затухания (диммирования) во время загрузки
            // Используем Modifier.graphicsLayer для плавной смены прозрачности без рекомпозиции
            items(uiState.logsList) { log ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .graphicsLayer {
                            // Если страница грузится, плавно приглушаем цвета до 50% прозрачности
                            alpha = if (uiState.isPageLoading) 0.5f else 1f
                        }
                        .padding(vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(text = log.readingName, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(2f))
                    Text(text = "${log.readingValue} ${log.readingUnit ?: ""}".trim(), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1.5f), textAlign = TextAlign.End)
                    Text(text = log.writeDateTime.take(16).replace("T", " "), style = MaterialTheme.typography.bodySmall, color = Color.Gray, modifier = Modifier.weight(2f), textAlign = TextAlign.End)
                }
                HorizontalDivider(color = colorScheme.outlineVariant.copy(alpha = 0.3f))
            }

            // Блок ПАГИНАТОРА (Кнопки блокируются во время загрузки страницы)
            if (uiState.logsList.isNotEmpty()) {
                item {
                    PaginationControl(
                        currentPage = uiState.currentPage,
                        totalCount = uiState.totalCount,
                        pageSize = 8,
                        // Запрещаем клики, если страница уже находится в процессе загрузки
                        onPageChanged = { newPage ->
                            if (!uiState.isPageLoading) onPageSelected(newPage)
                        }
                    )
                }
            }
        }

        // Большой спиннер показываем ТОЛЬКО при первой полной загрузке всего экрана (например, при смене прибора)
        if (uiState.isLoading && uiState.logsList.isEmpty()) {
            item {
                Box(modifier = Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(modifier = Modifier.size(32.dp))
                }
            }
        }

        // Нижние переключатели периодов
        item {
            Spacer(modifier = Modifier.height(16.dp))
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                var expanded by remember { mutableStateOf(false) }
                Box {
                    Button(onClick = { expanded = true }) {
                        Text(stringResource(uiState.selectedPeriod.resId))
                        Icon(Icons.Default.ArrowDropDown, contentDescription = null)
                    }
                    DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                        PeriodType.entries.forEach { period ->
                            DropdownMenuItem(text = { Text(stringResource(period.resId)) }, onClick = { onPeriodSelected(period); expanded = false })
                        }
                    }
                }
                // Переключатели режимов
                Row {
                    IconButton(onClick = { onViewModeChanged(true) }, colors = IconButtonDefaults.iconButtonColors(containerColor = if (uiState.isGraphView) colorScheme.primary else Color.Transparent, contentColor = if (uiState.isGraphView) colorScheme.onPrimary else colorScheme.onSurface)) { Icon(Icons.Default.Check, contentDescription = "Metric") }
                    IconButton(onClick = { onViewModeChanged(false) }, colors = IconButtonDefaults.iconButtonColors(containerColor = if (!uiState.isGraphView) colorScheme.primary else Color.Transparent, contentColor = if (!uiState.isGraphView) colorScheme.onPrimary else colorScheme.onSurface)) { Icon(Icons.Default.List, contentDescription = "Table") }
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
fun PaginationControl(
    currentPage: Int,
    totalCount: Int,
    pageSize: Int = 8,
    onPageChanged: (Int) -> Unit
) {
    val maxPages = ceil(totalCount.toDouble() / pageSize).toInt().coerceAtLeast(1)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        TextButton(
            onClick = { onPageChanged(1) },
            enabled = currentPage > 1
        ) { Text("◀◀", fontWeight = FontWeight.Bold) }

        TextButton(
            onClick = { onPageChanged(currentPage - 1) },
            enabled = currentPage > 1
        ) { Text("◀", fontWeight = FontWeight.Bold) }

        Card(
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
            modifier = Modifier.padding(horizontal = 8.dp)
        ) {
            Text(
                text = "$currentPage / $maxPages",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }

        TextButton(
            onClick = { onPageChanged(currentPage + 1) },
            enabled = currentPage < maxPages
        ) { Text("▶", fontWeight = FontWeight.Bold) }

        TextButton(
            onClick = { onPageChanged(maxPages) },
            enabled = currentPage < maxPages
        ) { Text("▶▶", fontWeight = FontWeight.Bold) }
    }
}

@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun DeviceListScreen(
    uiState: MainUiState,
    onDeviceSelected: (String) -> Unit
) {
    val groupedDevices = remember(uiState.devices) {
        uiState.devices.groupBy { it.model }
    }

    val expandedStates = remember {
        mutableStateMapOf<String, Boolean>().apply {
            groupedDevices.keys.forEach { model -> this[model] = true }
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Text(
            text = stringResource(R.string.connected_devices),
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            textAlign = TextAlign.Center,
            fontWeight = FontWeight.Bold
        )

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            groupedDevices.forEach { (model, devices) ->
                val isExpanded = expandedStates[model] ?: true

                stickyHeader {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(MaterialTheme.colorScheme.surfaceVariant)
                            .clickable {
                                expandedStates[model] = !isExpanded
                            }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = model,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Black,
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                        Icon(
                            imageVector = if (isExpanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                            contentDescription = if (isExpanded) "Hide" else "Expand",
                            tint = MaterialTheme.colorScheme.onPrimary
                        )
                    }
                }

                if (isExpanded) {
                    items(devices) { device ->
                        val isSelected = device.serialNumber == uiState.selectedDeviceId

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(if (isSelected) MaterialTheme.colorScheme.primaryContainer else Color.Transparent)
                                .clickable { onDeviceSelected(device.serialNumber) }
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = device.name,
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                )
                                Text(
                                    text = device.statusName,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color.Gray
                                )
                            }
                            if (isSelected) {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = "Checked",
                                    tint = colorScheme.onSurface
                                )
                            }
                        }
                        HorizontalDivider(color = colorScheme.outlineVariant.copy(alpha = 0.5f))
                    }
                }
            }
        }
    }
}

@Composable
fun LoadingStateScreen() {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
    }
}

@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun EmptyStateScreen(onRefresh: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.Clear,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.6f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = stringResource(R.string.state_empty_title),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.state_empty_subtitle),
            style = MaterialTheme.typography.bodyMedium,
            color = Color.Gray,
            textAlign = TextAlign.Center
        )
        TextButton(
            onClick = { onRefresh() }
        ) {
            Text(
                text = stringResource(R.string.state_empty_refresh),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}