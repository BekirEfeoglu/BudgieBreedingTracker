import java.util.Properties
import java.io.File
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
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

fun loadEnvFile(file: File): Map<String, String> {
    if (!file.exists()) return emptyMap()
    return file.readLines()
        .mapNotNull { rawLine ->
            val line = rawLine.trim()
            if (line.isEmpty() || line.startsWith("#")) return@mapNotNull null
            val separatorIndex = line.indexOf('=')
            if (separatorIndex <= 0) return@mapNotNull null
            val key = line.substring(0, separatorIndex).trim()
            if (key.isEmpty()) return@mapNotNull null
            var value = line.substring(separatorIndex + 1).trim()
            if (
                (value.startsWith("\"") && value.endsWith("\"")) ||
                (value.startsWith("'") && value.endsWith("'"))
            ) {
                value = value.substring(1, value.length - 1)
            }
            key to value
        }
        .toMap()
}

fun escapeForBuildConfig(value: String): String =
    value.replace("\\", "\\\\").replace("\"", "\\\"")

val envFileValues = loadEnvFile(rootProject.file("../.env"))

fun resolveRuntimeConfigValue(key: String, defaultValue: String = ""): String {
    val fromEnv = System.getenv(key)?.trim().orEmpty()
    if (fromEnv.isNotEmpty()) return fromEnv

    val fromLocalProperties = localProperties.getProperty(key)?.trim().orEmpty()
    if (fromLocalProperties.isNotEmpty()) return fromLocalProperties

    val fromEnvFile = envFileValues[key]?.trim().orEmpty()
    if (fromEnvFile.isNotEmpty()) return fromEnvFile

    return defaultValue
}

val supabaseUrlFromConfig = resolveRuntimeConfigValue("SUPABASE_URL")
val supabaseAnonKeyFromConfig = resolveRuntimeConfigValue("SUPABASE_ANON_KEY")
val sentryDsnFromConfig = resolveRuntimeConfigValue("SENTRY_DSN")
val sentryEnvironmentFromConfig = resolveRuntimeConfigValue("SENTRY_ENVIRONMENT", "production")
val revenueCatIosFromConfig = resolveRuntimeConfigValue("REVENUECAT_API_KEY_IOS")
val revenueCatAndroidFromConfig = resolveRuntimeConfigValue("REVENUECAT_API_KEY_ANDROID")
val googleWebClientIdFromConfig = resolveRuntimeConfigValue("GOOGLE_WEB_CLIENT_ID")
val googleIosClientIdFromConfig = resolveRuntimeConfigValue("GOOGLE_IOS_CLIENT_ID")

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

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.budgiebreeding.budgie_breeding_tracker"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        buildConfigField(
            "String",
            "SUPABASE_URL",
            "\"${escapeForBuildConfig(supabaseUrlFromConfig)}\""
        )
        buildConfigField(
            "String",
            "SUPABASE_ANON_KEY",
            "\"${escapeForBuildConfig(supabaseAnonKeyFromConfig)}\""
        )
        buildConfigField(
            "String",
            "SENTRY_DSN",
            "\"${escapeForBuildConfig(sentryDsnFromConfig)}\""
        )
        buildConfigField(
            "String",
            "SENTRY_ENVIRONMENT",
            "\"${escapeForBuildConfig(sentryEnvironmentFromConfig)}\""
        )
        buildConfigField(
            "String",
            "REVENUECAT_API_KEY_IOS",
            "\"${escapeForBuildConfig(revenueCatIosFromConfig)}\""
        )
        buildConfigField(
            "String",
            "REVENUECAT_API_KEY_ANDROID",
            "\"${escapeForBuildConfig(revenueCatAndroidFromConfig)}\""
        )
        buildConfigField(
            "String",
            "GOOGLE_WEB_CLIENT_ID",
            "\"${escapeForBuildConfig(googleWebClientIdFromConfig)}\""
        )
        buildConfigField(
            "String",
            "GOOGLE_IOS_CLIENT_ID",
            "\"${escapeForBuildConfig(googleIosClientIdFromConfig)}\""
        )
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
