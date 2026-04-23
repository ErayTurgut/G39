import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    // 🔥 GOOGLE LOGIN & FIREBASE BAĞLANTISI
    id("com.google.gms.google-services")
}

android {
    namespace = "com.eray.G39.app"
    compileSdk = 36 // Android 16 desteği
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 🔥 DESUGARING AKTİF EDİLDİ: Bildirim ve modern paketlerin Java 8+ desteği için şart
        isCoreLibraryDesugaringEnabled = true 
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.eray.G39.app"
        
        // 🔥 KRİTİK: Google Login ve Isar için 21'den aşağısı kurtarmaz.
        minSdk = flutter.minSdkVersion 
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Büyük projelerde (Firebase + Isar) multidex şarttır.
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔥 DESUGARING KÜTÜPHANESİ: Kırmızı hatayı silecek olan asıl satır budur
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // 🔥 G39 FIREBASE & GOOGLE AUTH STACK
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    
    // Multidex Desteği
    implementation("androidx.multidex:multidex:2.0.1")
}