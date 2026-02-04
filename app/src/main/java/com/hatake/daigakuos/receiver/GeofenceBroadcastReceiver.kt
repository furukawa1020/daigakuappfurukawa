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

import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.android.EntryPointAccessors
import dagger.hilt.components.SingletonComponent

class GeofenceBroadcastReceiver : BroadcastReceiver() {

    @EntryPoint
    @InstallIn(SingletonComponent::class)
    interface ReceiverEntryPoint {
        fun getUserContextRepository(): UserContextRepository
    }

    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent) ?: return
        
        if (geofencingEvent.hasError()) {
            Log.e("Geofence", "Error code: ${geofencingEvent.errorCode}")
            return
        }

        val geofenceTransition = geofencingEvent.geofenceTransition
        
        // Inject manually
        val appContext = context.applicationContext
        val entryPoint = EntryPointAccessors.fromApplication(appContext, ReceiverEntryPoint::class.java)
        val repository = entryPoint.getUserContextRepository()

        when (geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> {
                updateLocationState(repository, true)
            }
            Geofence.GEOFENCE_TRANSITION_EXIT -> {
                updateLocationState(repository, false)
            }
            else -> {
                // Unknown transition
            }
        }
    }

    private fun updateLocationState(repository: UserContextRepository, isOnCampus: Boolean) {
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                repository.setCampusState(isOnCampus)
                Log.d("Geofence", "State updated: $isOnCampus")
            } finally {
                pendingResult.finish()
            }
        }
    }
}
