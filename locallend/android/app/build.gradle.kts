import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase
    id("com.google.gms.google-services")
}

val dotenv = Properties().apply {
    val f = rootProject.file("../.env")
    if (f.exists()) FileInputStream(f).use { load(it) }
}
val mapsApiKey: String =
    (dotenv["GOOGLE_MAPS_API_KEY"] as String?)
        ?: System.getenv("GOOGLE_MAPS_API_KEY")
        ?: ""

android {
    namespace = "com.example.locallend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.locallend"
        // Firebase Auth needs 23, google_maps_flutter needs 21.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for flutter_local_notifications (scheduled alarms use newer Java APIs).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}
