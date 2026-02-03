package com.hatake.daigakuos

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.navigation.compose.rememberNavController
import com.hatake.daigakuos.ui.navigation.UniversityNavGraph
import com.hatake.daigakuos.ui.theme.DaigakuOSTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var userContextRepository: com.hatake.daigakuos.domain.repository.UserContextRepository

    // Kanazawa University Natural Science and Technology Hall 2
    private val GEOFENCE_LAT = 36.5447
    private val GEOFENCE_LNG = 136.6963
    private val GEOFENCE_RADIUS = 500f // Increased to 500m for better detection
    private val GEOFENCE_ID = "KANAZAWA_UNIVERSITY"

    private lateinit var geofencingClient: com.google.android.gms.location.GeofencingClient
    private lateinit var fusedLocationClient: com.google.android.gms.location.FusedLocationProviderClient
    
    private val geofencePendingIntent: android.app.PendingIntent by lazy {
        val intent = android.content.Intent(this, com.hatake.daigakuos.receiver.GeofenceBroadcastReceiver::class.java)
        android.app.PendingIntent.getBroadcast(
            this,
            0,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        geofencingClient = com.google.android.gms.location.LocationServices.getGeofencingClient(this)
        fusedLocationClient = com.google.android.gms.location.LocationServices.getFusedLocationProviderClient(this)
        
        checkPermissionsAndAddGeofence()

        setContent {
            DaigakuOSTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    UniversityNavGraph(navController = navController)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Force check location on Resume to catch "Already Inside" case
        forceCheckLocation()
    }

    private fun forceCheckLocation() {
        if (checkForegroundPermissions()) {
            try {
                // Show toast that we are checking
                android.widget.Toast.makeText(this, "現在地を確認中...", android.widget.Toast.LENGTH_SHORT).show()

                // Use getCurrentLocation for fresh highly accurate location (requires CancellationToken or null)
                fusedLocationClient.getCurrentLocation(
                    com.google.android.gms.location.Priority.PRIORITY_HIGH_ACCURACY,
                    null
                ).addOnSuccessListener { location ->
                    if (location != null) {
                        val results = FloatArray(1)
                        android.location.Location.distanceBetween(
                            location.latitude, location.longitude,
                            GEOFENCE_LAT, GEOFENCE_LNG,
                            results
                        )
                        val distanceInMeters = results[0]
                        val isInside = distanceInMeters <= GEOFENCE_RADIUS
                        
                        lifecycleScope.launch {
                            userContextRepository.setCampusState(isInside)
                        }
                        
                        val status = if (isInside) "大学内 (距離: ${distanceInMeters.toInt()}m)" else "大学外 (距離: ${distanceInMeters.toInt()}m)"
                        android.widget.Toast.makeText(this, status, android.widget.Toast.LENGTH_LONG).show()
                        android.util.Log.d("LocationCheck", "Distance: $distanceInMeters m, IsInside: $isInside")
                    } else {
                        android.widget.Toast.makeText(this, "位置情報を取得できませんでした", android.widget.Toast.LENGTH_SHORT).show()
                    }
                }.addOnFailureListener {
                     android.widget.Toast.makeText(this, "位置情報エラー: ${it.message}", android.widget.Toast.LENGTH_SHORT).show()
                }
            } catch (e: SecurityException) {
                // Handle exception
            }
        } else {
             android.widget.Toast.makeText(this, "位置情報権限がありません", android.widget.Toast.LENGTH_SHORT).show()
        }
    }
// ... rest of checking permissions and geofence adding ...
    private val requestBackgroundPermissionLauncher = registerForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            addGeofence()
            forceCheckLocation()
        } else {
            android.util.Log.w("Geofence", "Background location permission denied.")
        }
    }

    private val requestPermissionLauncher = registerForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineLocationGranted = permissions[android.Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        
        if (fineLocationGranted) {
            checkAndRequestBackgroundPermission()
            forceCheckLocation()
        } else {
            // Foreground denied.
        }
    }
// ... remaining methods ...
    private fun checkPermissionsAndAddGeofence() {
        if (checkForegroundPermissions()) {
             checkAndRequestBackgroundPermission()
             forceCheckLocation()
        } else {
            requestForegroundPermissions()
        }
    }
    
    // ... rest of methods (checkForegroundPermissions, requestForegroundPermissions, checkAndRequestBackgroundPermission, addGeofence)
    // Be careful to keep existing methods intact or rewrite them.
    // I will rewrite the changed parts and keep the rest.


    private fun checkForegroundPermissions(): Boolean {
        return androidx.core.content.ContextCompat.checkSelfPermission(
            this, 
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun requestForegroundPermissions() {
        requestPermissionLauncher.launch(
            arrayOf(
                android.Manifest.permission.ACCESS_FINE_LOCATION,
                android.Manifest.permission.ACCESS_COARSE_LOCATION
            )
        )
    }

    private fun checkAndRequestBackgroundPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            val backgroundLocation = androidx.core.content.ContextCompat.checkSelfPermission(
                this, 
                android.Manifest.permission.ACCESS_BACKGROUND_LOCATION
            )
            
            if (backgroundLocation == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                addGeofence()
            } else {
                // Request Background Permission
                // Note: On Android 11+, this must be requested INDEPENDENTLY after foreground is granted.
                requestBackgroundPermissionLauncher.launch(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION)
            }
        } else {
            // Android 9 or lower, background is included in fine
            addGeofence()
        }
    }

    private fun addGeofence() {
        val geofence = com.google.android.gms.location.Geofence.Builder()
            .setRequestId(GEOFENCE_ID)
            .setCircularRegion(GEOFENCE_LAT, GEOFENCE_LNG, GEOFENCE_RADIUS)
            .setExpirationDuration(com.google.android.gms.location.Geofence.NEVER_EXPIRE)
            .setTransitionTypes(com.google.android.gms.location.Geofence.GEOFENCE_TRANSITION_ENTER or com.google.android.gms.location.Geofence.GEOFENCE_TRANSITION_EXIT)
            .build()

        val geofencingRequest = com.google.android.gms.location.GeofencingRequest.Builder()
            .setInitialTrigger(com.google.android.gms.location.GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()

        if (androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            geofencingClient.addGeofences(geofencingRequest, geofencePendingIntent).run { 
                addOnSuccessListener { 
                    android.util.Log.d("Geofence", "Geofence Added Successfully")
                }
                addOnFailureListener { 
                    android.util.Log.e("Geofence", "Geofence Add Failed: ${it.message}")
                }
            }
        }
    }
}
