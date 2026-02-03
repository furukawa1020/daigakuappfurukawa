import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    
    // Local State for fields to allow editing
    var latInput by remember(uiState) { mutableStateOf(uiState.campusLat.toString()) }
    var lngInput by remember(uiState) { mutableStateOf(uiState.campusLng.toString()) }
    var radInput by remember(uiState) { mutableStateOf(uiState.campusRadiusM.toString()) }
    var targetInput by remember(uiState) { mutableStateOf(uiState.weeklyHourTarget.toString()) }

    // Update local state when loading finishes (if needed, but remember(uiState) handles it usually if key changes. 
    // Here uiState changes on save. To avoid overwrite during typing, we might need separate "isLoaded" check or simple approach)
    // For MVP, syncing on uiState change is risky if typing triggers updates, but uiState only updates on Save/Load.
    
    LaunchedEffect(uiState) {
        if (!uiState.isLoading) {
            latInput = uiState.campusLat.toString()
            lngInput = uiState.campusLng.toString()
            radInput = uiState.campusRadiusM.toString()
            targetInput = uiState.weeklyHourTarget.toString()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("設定") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
                .fillMaxSize()
        ) {
            Text("キャンパス位置設定 (Geofence)", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))
            
            OutlinedTextField(
                value = latInput,
                onValueChange = { latInput = it },
                label = { Text("緯度 (Latitude)") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = lngInput,
                onValueChange = { lngInput = it },
                label = { Text("経度 (Longitude)") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = radInput,
                onValueChange = { radInput = it },
                label = { Text("半径 (Meter)") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            HorizontalDivider()
            Spacer(modifier = Modifier.height(24.dp))
            
            Text("目標設定", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))
            
            OutlinedTextField(
                value = targetInput,
                onValueChange = { targetInput = it },
                label = { Text("週の目標時間 (Hours)") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            Button(
                onClick = {
                    val lat = latInput.toDoubleOrNull()
                    val lng = lngInput.toDoubleOrNull()
                    val rad = radInput.toFloatOrNull()
                    val target = targetInput.toIntOrNull()
                    
                    if (lat != null && lng != null && rad != null && target != null) {
                        viewModel.saveSettings(lat, lng, rad, target)
                        // Trigger Snackbar?
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("保存")
            }
        }
    }
}
