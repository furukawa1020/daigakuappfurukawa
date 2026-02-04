buildscript {
    repositories {
        maven { url = uri("https://maven.google.com") }
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        classpath("com.google.dagger:hilt-android-gradle-plugin:2.48")
        classpath("com.google.devtools.ksp:symbol-processing-gradle-plugin:2.1.0-1.0.29")
        classpath("javax.xml.bind:jaxb-api:2.3.1")
        classpath("org.glassfish.jaxb:jaxb-runtime:2.3.1")
    }
}

// Top-level build file where you can add configuration options common to all sub-projects/modules.
