import com.android.build.api.dsl.ApplicationExtension
import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: read from android/key.properties (gitignored). Locally the
// file points at your own keystore; in CI the release workflow writes it from
// repository secrets. When it's missing, release builds fall back to the debug
// key so `flutter run --release` still works on a fresh checkout.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

// 023 Bank SMS Import (CHK013, research Decision 3): the one capability
// switch. Only when DAFTARY_SMS_IMPORT=true (or the Gradle property
// -Pdaftary.smsImport=true) is the READ_SMS-only overlay manifest
// sms_capability/AndroidManifest.xml merged in. Default off: the main
// manifest never declares READ_SMS. There is no Dart const or
// --dart-define; Dart learns the result from the installed package's
// requested permissions (SmsPlugin.getCapabilities). Read through
// providers so the configuration cache tracks the value.
val smsImportCapability: Boolean =
    providers.environmentVariable("DAFTARY_SMS_IMPORT").orNull == "true" ||
        providers.gradleProperty("daftary.smsImport").orNull == "true"

configure<ApplicationExtension> {
    namespace = "com.daftary.daftary"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (017) for its scheduled-
        // notification support on older Android versions.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.daftary.daftary"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

androidComponents {
    onVariants { variant ->
        if (smsImportCapability) {
            variant.sources.manifests.addStaticManifestFile(
                "sms_capability/AndroidManifest.xml",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
