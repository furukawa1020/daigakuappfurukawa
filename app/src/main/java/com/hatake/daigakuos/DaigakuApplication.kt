package com.hatake.daigakuos

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class DaigakuApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Initialize other libs if needed
    }
}
