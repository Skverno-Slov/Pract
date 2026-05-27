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

import com.patrykandpatrick.vico.compose.cartesian.CartesianChartHost
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLineCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLine
import com.patrykandpatrick.vico.compose.cartesian.rememberCartesianChart
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberBottom
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberStart
import com.patrykandpatrick.vico.compose.common.component.rememberLineComponent
import com.patrykandpatrick.vico.core.cartesian.axis.HorizontalAxis
import com.patrykandpatrick.vico.core.cartesian.axis.VerticalAxis
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import com.patrykandpatrick.vico.core.cartesian.layer.LineCartesianLayer
import com.patrykandpatrick.vico.core.common.component.LineComponent
import com.rtsr.signal.dtos.GraphPointDto
import kotlin.math.abs

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
    onPageSelected: (Int) -> Unit
) {
    val currentDevice = uiState.devices.find { it.serialNumber == uiState.selectedDeviceId }
    val colorScheme = MaterialTheme.colorScheme

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp)
    ) {
        item {
            Spacer(modifier = Modifier.height(16.dp))
            Text(text = stringResource(R.string.data_actual_at, uiState.lastUpdateTime), style = MaterialTheme.typography.bodySmall, color = Color.Gray)
            Spacer(modifier = Modifier.height(4.dp))
            Text(text = currentDevice?.name ?: "—", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(12.dp))

            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                item { FilterChip(selected = uiState.selectedParamIdentifier == null, onClick = { onParamSelected(null) }, label = { Text("Все") }) }
                items(uiState.availableParams) { paramId ->
                    FilterChip(selected = uiState.selectedParamIdentifier == paramId, onClick = { onParamSelected(paramId) }, label = { Text(paramId) }) }
            }
            Spacer(modifier = Modifier.height(12.dp))
        }

        if (uiState.isGraphView) {
            item {
                if (uiState.isGraphLoading) {
                    Box(modifier = Modifier.fillMaxWidth().height(280.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                } else {
                    InteractiveParamChart(
                        graphPoints = uiState.graphPoints,
                        selectedParam = uiState.selectedParamIdentifier,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        } else {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
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

            item {
                Row(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(text = "Показание", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, modifier = Modifier.weight(2f))
                    Text(text = "Значение", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1.5f), textAlign = TextAlign.End)
                    Text(text = "Дата", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, modifier = Modifier.weight(2f), textAlign = TextAlign.End)
                }
                HorizontalDivider(color = colorScheme.outlineVariant)
            }

            items(uiState.logsList) { log ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .graphicsLayer {
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

            if (uiState.logsList.isNotEmpty()) {
                item {
                    PaginationControl(
                        currentPage = uiState.currentPage,
                        totalCount = uiState.totalCount,
                        pageSize = 8,
                        onPageChanged = { newPage ->
                            if (!uiState.isPageLoading) onPageSelected(newPage)
                        }
                    )
                }
            }
        }

        if (uiState.isLoading && uiState.logsList.isEmpty()) {
            item {
                Box(modifier = Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(modifier = Modifier.size(32.dp))
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
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
fun InteractiveParamChart(
    graphPoints: List<GraphPointDto>,
    selectedParam: String?,
    modifier: Modifier = Modifier
) {
    val filteredPoints = remember(graphPoints, selectedParam) {
        if (selectedParam == null) graphPoints else graphPoints.filter { it.param == selectedParam }
    }

    if (filteredPoints.isEmpty()) {
        Box(modifier = modifier.height(300.dp), contentAlignment = Alignment.Center) {
            Text("Нет данных для графика", color = Color.Gray)
        }
        return
    }

    val validNumericPoints = remember(filteredPoints) {
        filteredPoints.filter { point ->
            val cleanValue = point.`value`.replace(",", ".")
            val floatVal = cleanValue.toFloatOrNull()
            floatVal != null && !floatVal.isNaN() && !floatVal.isInfinite()
        }
    }

    val optimizedPoints = remember(validNumericPoints) {
        val maxPoints = 500
        if (validNumericPoints.size > maxPoints) {
            val step = validNumericPoints.size / maxPoints
            validNumericPoints.filterIndexed { index, _ -> index % step == 0 }
        } else {
            validNumericPoints
        }
    }

    val groupedPoints = remember(optimizedPoints) { optimizedPoints.groupBy { it.param } }

    val paramBounds = remember(optimizedPoints) {
        groupedPoints.mapValues { (_, points) ->
            val values = points.map { it.`value`.replace(",", ".").toFloatOrNull() ?: 0f }
            val min = values.minOrNull() ?: 0f
            val max = values.maxOrNull() ?: 100f
            val delta = if (max == min || (max - min) == 0f) 1f else max - min
            (min - delta * 0.1f) to (max + delta * 0.1f)
        }
    }

    val globalMinMax = remember(paramBounds) {
        val mins = paramBounds.values.map { it.first }
        val maxs = paramBounds.values.map { it.second }
        (mins.minOrNull() ?: 0f) to (maxs.maxOrNull() ?: 100f)
    }

    var scaleX by remember { mutableStateOf(1f) }
    var offsetX by remember { mutableStateOf(0f) }

    val transformState = rememberTransformableState { zoomChange, offsetChange, _ ->
        scaleX = (scaleX * zoomChange).coerceIn(1f, 30f)
        offsetX += offsetChange.x
    }

    val colorScheme = MaterialTheme.colorScheme

    Column(modifier = modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(280.dp)
                .background(colorScheme.surfaceVariant.copy(alpha = 0.2f))
                .transformable(state = transformState)
        ) {
            Canvas(modifier = Modifier.fillMaxSize().padding(start = 50.dp, bottom = 30.dp, top = 10.dp, end = 10.dp)) {
                val width = size.width
                val height = size.height

                val maxOffset = 0f
                val minOffset = -(width * scaleX - width)
                offsetX = offsetX.coerceIn(minOffset, maxOffset)

                for (i in 0..4) {
                    val yCoeff = i.toFloat() / 4f
                    val yPos = height - (yCoeff * height)
                    drawLine(
                        color = Color.LightGray.copy(alpha = 0.4f),
                        start = Offset(0f, yPos),
                        end = Offset(width, yPos),
                        strokeWidth = 1.dp.toPx()
                    )
                }

                groupedPoints.forEach { (paramName, points) ->
                    if (points.size < 2) return@forEach

                    val path = Path()
                    val xSpacing = width / (points.size - 1)
                    var isFirst = true

                    val bounds = paramBounds[paramName] ?: (0f to 100f)
                    val pMin = bounds.first
                    val pMax = bounds.second
                    val pRange = if ((pMax - pMin) == 0f) 1f else (pMax - pMin)

                    points.forEachIndexed { index, point ->
                        val cleanValue = point.`value`.replace(",", ".")
                        val yVal = cleanValue.toFloatOrNull() ?: return@forEachIndexed

                        val xPos = (index * xSpacing * scaleX) + offsetX
                        val yPos = height - (((yVal - pMin) / pRange) * height)

                        if (!xPos.isNaN() && !xPos.isInfinite() && !yPos.isNaN() && !yPos.isInfinite()) {
                            if (isFirst) {
                                path.moveTo(xPos, yPos)
                                isFirst = false
                            } else {
                                path.lineTo(xPos, yPos)
                            }
                        }
                    }

                    if (!isFirst) {
                        drawPath(
                            path = path,
                            color = getParamColor(paramName),
                            style = Stroke(width = 2.dp.toPx())
                        )
                    }
                }
            }

            Column(
                modifier = Modifier.fillMaxHeight().padding(bottom = 30.dp, top = 10.dp, start = 6.dp),
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                val bounds = if (selectedParam != null) paramBounds[selectedParam] ?: (0f to 100f) else globalMinMax
                val yMin = bounds.first
                val yMax = bounds.second
                val step = (yMax - yMin) / 4f

                for (i in 4 downTo 0) {
                    val value = yMin + (step * i)
                    val textToShow = if (value.isNaN() || value.isInfinite()) "0.0" else String.format(java.util.Locale.US, "%.1f", value)
                    Text(
                        text = textToShow,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Gray
                    )
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomStart)
                    .padding(start = 50.dp, bottom = 4.dp, end = 10.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                if (optimizedPoints.size >= 3) {
                    val firstTime = optimizedPoints.first().dt.substringAfter("T").take(5)
                    val midTime = optimizedPoints[optimizedPoints.size / 2].dt.substringAfter("T").take(5)
                    val lastTime = optimizedPoints.last().dt.substringAfter("T").take(5)

                    Text(text = firstTime, fontSize = 10.sp, color = Color.Gray)
                    Text(text = midTime, fontSize = 10.sp, color = Color.Gray)
                    Text(text = lastTime, fontSize = 10.sp, color = Color.Gray)
                }
            }
        }
    }
}

fun getParamColor(paramIdentifier: String?): Color {
    if (paramIdentifier.isNullOrBlank()) return Color.Gray
    val colors = listOf(
        Color(0xFF007AFF),
        Color(0xFF34C759),
        Color(0xFFFF9500),
        Color(0xFFFF2D55),
        Color(0xFF5856D6),
        Color(0xFFAF52DE)
    )
    val positiveHashCode = paramIdentifier.hashCode() and 0x7FFFFFFF
    val index = positiveHashCode % colors.size
    return colors[index]
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