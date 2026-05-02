plugins {
    id("com.android.application") version "8.5.0" apply false
    id("com.android.library") version "8.5.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Relocate build directory to the root of the workspace to avoid 
// Git 'too many changes' errors and keep the android folder clean.
rootProject.layout.buildDirectory.set(rootProject.projectDir.parentFile.resolve("build"))

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
