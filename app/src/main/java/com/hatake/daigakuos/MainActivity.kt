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

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    // Hardcoded for MVP: Update with real coordinates
    // Generic Tokyo University area placeholder
    private val GEOFENCE_LAT = 35.7127
    private val GEOFENCE_LNG = 139.758
    private val GEOFENCE_RADIUS = 500f // meters
    private val GEOFENCE_ID = "UNIVERSITY_CAMPUS"

    private lateinit var geofencingClient: com.google.android.gms.location.GeofencingClient
    
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

    private fun checkPermissionsAndAddGeofence() {
        val fineLocation = androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION)
        val backgroundLocation = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            androidx.core.content.ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        } else {
            android.content.pm.PackageManager.PERMISSION_GRANTED
        }

        if (fineLocation == android.content.pm.PackageManager.PERMISSION_GRANTED &&
            backgroundLocation == android.content.pm.PackageManager.PERMISSION_GRANTED) {
            addGeofence()
        } else {
            // Request permissions
            val permissions = mutableListOf(android.Manifest.permission.ACCESS_FINE_LOCATION, android.Manifest.permission.ACCESS_COARSE_LOCATION)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                permissions.add(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION)
            }
            
            requestPermissionLauncher.launch(permissions.toTypedArray())
        }
    }

    private val requestPermissionLauncher = registerForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineLocationGranted = permissions[android.Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        val backgroundLocationGranted = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            permissions[android.Manifest.permission.ACCESS_BACKGROUND_LOCATION] ?: false
        } else true

        if (fineLocationGranted && backgroundLocationGranted) {
            addGeofence()
        } else {
            // Show rationale or fail nicely
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
