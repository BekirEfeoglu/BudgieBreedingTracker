import java.util.Properties
import java.io.File
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val releaseStorePath = keystoreProperties.getProperty("storeFile")?.trim().orEmpty()
val releaseStoreFile = releaseStorePath.takeIf { it.isNotEmpty() }?.let { configuredPath ->
    val isWindowsAbsolutePath = Regex("^[A-Za-z]:[\\\\/].*").matches(configuredPath)
    if (isWindowsAbsolutePath) {
        File(configuredPath)
    } else {
        rootProject.file(configuredPath)
    }
}
val hasReleaseSigningConfig =
    keystorePropertiesFile.exists() &&
    !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyPassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
    releaseStoreFile?.exists() == true

val isCiBuild = System.getenv("CI") == "true" || !System.getenv("CM_BUILD_ID").isNullOrBlank()
val isReleaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true)
}

android {
    namespace = "com.budgiebreeding.budgie_breeding_tracker"
    compileSdk = 36
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
        applicationId = "com.budgiebreeding.budgie_breeding_tracker"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = releaseStoreFile
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (isCiBuild && isReleaseTaskRequested && !hasReleaseSigningConfig) {
                throw org.gradle.api.GradleException(
                    "Release signing is not fully configured for CI. Ensure android/key.properties exists and storeFile points to a valid keystore."
                )
            }
            if (!isCiBuild && isReleaseTaskRequested && !hasReleaseSigningConfig) {
                logger.warn(
                    "Release keystore not found or invalid (storeFile='{}'). Using debug signing for local build.",
                    releaseStorePath.ifBlank { "<missing>" }
                )
            }
            signingConfig = if (hasReleaseSigningConfig) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        jniLibs.useLegacyPackaging = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
