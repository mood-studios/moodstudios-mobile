plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.moodstudios.mood_studios_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.moodstudios.mood_studios_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
}

gradle.buildFinished {
    if (failure != null) return@buildFinished
    val taskNames = project.gradle.startParameter.taskNames
    if (taskNames.none { it.contains("assembleRelease", ignoreCase = true) }) {
        return@buildFinished
    }

    val flutterApkDir = file("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
    if (!flutterApkDir.isDirectory) return@buildFinished

    val source = flutterApkDir.listFiles()
        ?.filter { it.isFile && it.extension.equals("apk", ignoreCase = true) && it.name != "moodstudios.apk" }
        ?.sortedWith(
            compareByDescending<File> { it.name.contains("release", ignoreCase = true) }
                .thenByDescending { it.lastModified() },
        )
        ?.firstOrNull()
        ?: return@buildFinished

    val dest = File(flutterApkDir, "moodstudios.apk")
    source.copyTo(dest, overwrite = true)
    logger.lifecycle("Mood Studios release APK also saved as: ${dest.absolutePath}")

    val releaseDir = layout.buildDirectory.dir("outputs/apk/release").get().asFile
    if (releaseDir.isDirectory) {
        source.copyTo(File(releaseDir, "moodstudios.apk"), overwrite = true)
    }
}
