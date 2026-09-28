import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (!keystorePropertiesFile.exists()) {
    throw GradleException(
        "Missing android/key.properties"
    )
}

FileInputStream(keystorePropertiesFile).use {
    keystoreProperties.load(it)
}

val releaseKeyAlias =
    keystoreProperties.getProperty("keyAlias")
        ?: throw GradleException("keyAlias missing in key.properties")

val releaseKeyPassword =
    keystoreProperties.getProperty("keyPassword")
        ?: throw GradleException("keyPassword missing in key.properties")

val releaseStorePassword =
    keystoreProperties.getProperty("storePassword")
        ?: throw GradleException("storePassword missing in key.properties")

val releaseStoreFileName =
    keystoreProperties.getProperty("storeFile")
        ?: throw GradleException("storeFile missing in key.properties")

val releaseStoreFile = file(releaseStoreFileName)

if (!releaseStoreFile.exists()) {
    throw GradleException(
        "Keystore not found: ${releaseStoreFile.absolutePath}"
    )
}

android {
    namespace = "com.vexora.vexora_rush"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.vexora.vexora_rush"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
            storePassword = releaseStorePassword
            storeFile = releaseStoreFile
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // IMPORTANT:
            // Prevent R8 from breaking WorkManager / Room in release builds.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}