package com.rtsr.signal.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.rtsr.signal.R
import com.rtsr.signal.models.MainUiState

@Composable
fun SettingsScreen(
    uiState: MainUiState,
    onSaveClick: (String, String) -> Unit,
    onAddressValueChange: () -> Unit,
    onPortValueChange: () -> Unit
) {
    var address by remember { mutableStateOf(uiState.apiAddress) }
    var port by remember { mutableStateOf(uiState.apiPort) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = stringResource(R.string.settings_title),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 32.dp, top = 16.dp)
        )

        Row {
            OutlinedTextField(
                value = address,
                onValueChange = {
                    address = it
                    onAddressValueChange()
                },
                label = { Text(stringResource(R.string.api_address_hint)) },
                modifier = Modifier.weight(0.7f),
                isError = uiState.addressErrorResId != null,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                supportingText = {
                    uiState.addressErrorResId?.let { resId ->
                        Text(text = stringResource(resId), color = MaterialTheme.colorScheme.error)
                    }
                }
            )

            OutlinedTextField(
                value = port,
                onValueChange = {
                    port = it
                    onPortValueChange()
                },
                label = { Text(stringResource(R.string.port_hint)) },
                modifier = Modifier.weight(0.3f),
                isError = uiState.portErrorResId != null,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                supportingText = {
                    uiState.portErrorResId?.let { resId ->
                        Text(text = stringResource(resId), color = MaterialTheme.colorScheme.error)
                    }
                }
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row {
            Button(
                onClick = { onSaveClick(address, port) },
                modifier = Modifier
                    .weight(0.5f)
                    .height(50.dp)
            ) {
                Text(
                    text = stringResource(R.string.btn_save),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }


            Button(
                onClick = { /*TODO:Реализовать проверку*/ },
                modifier = Modifier
                    .weight(0.5f)
                    .height(50.dp)
            ) {
                Text(
                    text = stringResource(R.string.btn_check_connection),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}