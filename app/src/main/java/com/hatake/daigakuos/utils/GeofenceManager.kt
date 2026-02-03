package com.hatake.daigakuos.utils

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import com.hatake.daigakuos.receiver.GeofenceBroadcastReceiver
import kotlinx.coroutines.tasks.await

class GeofenceManager(private val context: Context) {

    private val geofencingClient = LocationServices.getGeofencingClient(context)

    // Center of University Node (Example Coords)
    // 36.5626° N, 136.6623° E (Kanazawa University kakuma?)
    // User provided maps, we can refine this later. 
    // For now, let's use a constant.
    companion object {
        const val UNIVERSITY_GEOFENCE_ID = "UNIVERSITY_ZONE"
        const val GEOFENCE_RADIUS_METERS = 150f // As per requirement (50-150m)
        // Placeholder coordinates, user should update these
        const val LATITUDE = 36.54637
        const val LONGITUDE = 136.70582 
    }

    private val geofencePendingIntent: PendingIntent by lazy {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }

    @SuppressLint("MissingPermission") // Caller must ensure permissions
    suspend fun addGeofence() {
        val geofence = Geofence.Builder()
            .setRequestId(UNIVERSITY_GEOFENCE_ID)
            .setCircularRegion(LATITUDE, LONGITUDE, GEOFENCE_RADIUS_METERS)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
            .build()

        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()

        try {
            geofencingClient.addGeofences(request, geofencePendingIntent).await()
            // Log success
        } catch (e: Exception) {
            // Log failure
            e.printStackTrace()
        }
    }

    suspend fun removeGeofence() {
        try {
            geofencingClient.removeGeofences(geofencePendingIntent).await()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
