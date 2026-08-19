import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ── Transitive dependency pinning ────────────────────────────────────────────
// `home_widget` pulls in androidx.glance. Glance 1.2.x / 1.3.0-alpha publish AAR
// metadata that demands compileSdk 37 AND Android Gradle Plugin 9.1.0+, which
// fails :app:checkDebugAarMetadata on this project (AGP 8.11.1 / compileSdk 36).
//
// Quran2U's prayer-times widget is a classic AppWidgetProvider + RemoteViews
// (see PrayerTimesWidgetProvider.kt) — it does not use Glance at all — so the
// last stable Glance release is more than sufficient.
//
// Remove this block only after moving the project to AGP 9.x + compileSdk 37.
allprojects {
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.glance") {
                useVersion("1.1.0")
                because(
                    "Glance 1.2+/1.3.0-alpha require compileSdk 37 and AGP 9.x; " +
                        "this project builds with AGP 8.11.1 and compileSdk 36.",
                )
            }
        }
    }
}

// ── JVM target alignment for every Flutter plugin module ─────────────────────
// Several plugins (home_widget among them) still compile at Java/Kotlin 1.8.
// Modern AndroidX artifacts — androidx.glance, work-runtime-ktx, etc. — ship
// JVM 11 bytecode, and Kotlin refuses to inline JVM 11 bytecode into a 1.8
// target:
//
//   e: HomeWidgetBackgroundWorker.kt:118:11 Cannot inline bytecode built with
//      JVM target 11 into bytecode that is being built with JVM target 1.8.
//
// Raising every subproject to 17 (what :app already uses) fixes that and also
// silences the "source value 8 is obsolete" warnings from javac.
//
// Java and Kotlin are raised together on purpose: leaving javac at 1.8 while
// Kotlin emits version-61 class files breaks joint compilation in any module
// that mixes the two languages.
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
