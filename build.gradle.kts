buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("javax.xml.bind:jaxb-api:2.3.1")
        classpath("org.glassfish.jaxb:jaxb-runtime:2.3.1")
    }
}

// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    id("com.android.application") version "8.5.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    id("com.google.dagger.hilt.android") version "2.48" apply false
    id("com.google.devtools.ksp") version "1.9.0-1.0.13" apply false
}
