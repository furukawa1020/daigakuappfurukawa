package com.hatake.daigakuos.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import com.hatake.daigakuos.domain.repository.UserContextRepository
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class GeofenceBroadcastReceiver : BroadcastReceiver() {

    @Inject
    lateinit var userContextRepository: UserContextRepository

    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent) ?: return
        
        if (geofencingEvent.hasError()) {
            Log.e("Geofence", "Error code: ${geofencingEvent.errorCode}")
            return
        }

        val geofenceTransition = geofencingEvent.geofenceTransition

        when (geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> {
                updateLocationState(true)
            }
            Geofence.GEOFENCE_TRANSITION_EXIT -> {
                updateLocationState(false)
            }
            else -> {
                // Unknown transition
            }
        }
    }

    private fun updateLocationState(isOnCampus: Boolean) {
        // We need to launch a coroutine because onReceive is on main thread (usually) 
        // and repository might be suspect or main-safe.
        CoroutineScope(Dispatchers.IO).launch {
            userContextRepository.setCampusState(isOnCampus)
        }
    }
}
