import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Properly loading properties in Kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun prop(name: String): String? =
    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }

val releaseStoreFile = prop("storeFile")?.let { file(it) }
val hasReleaseSigning =
    releaseStoreFile != null &&
        releaseStoreFile.exists() &&
        prop("storePassword") != null &&
        prop("keyPassword") != null &&
        prop("keyAlias") != null

android {
    namespace = "com.quran2u.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true 
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.quran2u.app" 
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders += mapOf("appAuthRedirectScheme" to "quran2u")
    }

    signingConfigs {
        create("release") {
            keyAlias = prop("keyAlias")
            keyPassword = prop("keyPassword")
            if (releaseStoreFile != null) {
                storeFile = releaseStoreFile
            }
            storePassword = prop("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            // If release keystore is not configured, fall back to debug signing
            // to avoid blocking local release builds. Configure `android/key.properties`
            // to use the real release keystore.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}