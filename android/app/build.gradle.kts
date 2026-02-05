import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")


}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    println("DEBUG: key.properties loaded from ${keystorePropertiesFile.absolutePath}")
} else {
    println("DEBUG: key.properties NOT found at ${keystorePropertiesFile.absolutePath}")
}

    android {
        namespace = "com.nminfotech.bneeds_taxi_driver"
        compileSdk = flutter.compileSdkVersion
        ndkVersion = flutter.ndkVersion

        compileOptions {
            sourceCompatibility = JavaVersion.VERSION_11
            targetCompatibility = JavaVersion.VERSION_11
            isCoreLibraryDesugaringEnabled = true
        }

        kotlinOptions {
            jvmTarget = JavaVersion.VERSION_11.toString()
        }

        defaultConfig {
            // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
            applicationId = "com.nminfotech.bneeds_taxi_driver"
            // You can update the following values to match your application needs.
            // For more information, see: https://flutter.dev/to/review-gradle-config.
            minSdk = flutter.minSdkVersion
            targetSdk = flutter.targetSdkVersion
            versionCode = 3
            versionName = flutter.versionName
        }

        signingConfigs {
            create("release") {
                val cleanProps = mutableMapOf<String, String>()

                // UTF-16 / BOM detection and cleaning logic
                if (keystorePropertiesFile.exists()) {
                    try {
                        // Read all bytes and detect UTF-16
                        val bytes = keystorePropertiesFile.readBytes()
                        val content = if (bytes.size >= 2 && ((bytes[0].toInt() == -1 && bytes[1].toInt() == -2) || (bytes[0].toInt() == -2 && bytes[1].toInt() == -1))) {
                            // It's UTF-16, let's decode it properly
                            String(bytes, charset("UTF-16"))
                        } else {
                            // Fallback to default
                            String(bytes)
                        }

                        // Parse manually since Properties.load() fails items with null bytes in between
                        content.lines().forEach { line ->
                            val cleanLine = line.replace("\uFEFF", "").trim()
                            if (cleanLine.contains("=")) {
                                val parts = cleanLine.split("=", limit = 2)
                                val key = parts[0].trim()
                                val value = parts[1].trim()
                                if (key.isNotEmpty()) {
                                    cleanProps[key] = value
                                }
                            }
                        }
                    } catch (e: Exception) {
                        println("DEBUG: Error manually parsing properties: ${e.message}")
                    }
                }

                // If manual parsing failed or found nothing, try the loaded properties
                if (cleanProps.isEmpty()) {
                    keystoreProperties.forEach { k, v ->
                        val key = k.toString().replace("\uFEFF", "").replace("ÿþ", "").replace("\u0000", "").trim()
                        val value = v.toString().replace("\u0000", "").trim()
                        if (key.isNotEmpty()) cleanProps[key] = value
                    }
                }

                val alias = cleanProps["keyAlias"]
                val keyPass = cleanProps["keyPassword"]
                val storePass = cleanProps["storePassword"]
                val storeFilePath = cleanProps["storeFile"]

                println("DEBUG: Final Cleaned Alias: $alias")
                println("DEBUG: Final Cleaned StoreFile: $storeFilePath")

                if (alias != null && keyPass != null && storePass != null && storeFilePath != null) {
                    keyAlias = alias
                    keyPassword = keyPass
                    storeFile = rootProject.file(storeFilePath)
                    storePassword = storePass
                    println("DEBUG: Release signing config set up SUCCESS with file: ${storeFile?.absolutePath}")
                } else {
                    println("DEBUG: ERROR: Release signing config is MISSING properties!")
                    cleanProps.forEach { (k, v) -> println("DEBUG: Found Key='$k', Value='$v'") }
                }
            }
        }
        buildTypes {
            release {
                // TODO: Add your own signing config for the release build.
                // Signing with the debug keys for now,
                // so `flutter run --release` works.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            }
        }
    }

    flutter {
        source = "../.."
    }
    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    }
