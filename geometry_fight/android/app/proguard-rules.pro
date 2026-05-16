# =============================================================================
# ProGuard / R8 rules for Geometry Fight (Flutter + Flame + Hive)
# =============================================================================
# Applied alongside getDefaultProguardFile("proguard-android-optimize.txt") in
# android/app/build.gradle.kts when isMinifyEnabled / isShrinkResources are on.

# -----------------------------------------------------------------------------
# Flutter engine + embedding
# -----------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# -----------------------------------------------------------------------------
# AndroidX / Material
# -----------------------------------------------------------------------------
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**
-keep class androidx.** { *; }
-dontwarn androidx.**

# -----------------------------------------------------------------------------
# Flame engine (reflection-light, but keep generated/internal symbols)
# -----------------------------------------------------------------------------
-keep class org.flame_engine.** { *; }
-dontwarn org.flame_engine.**

# -----------------------------------------------------------------------------
# Hive — type adapters are looked up reflectively at runtime
# -----------------------------------------------------------------------------
-keep class * extends hive.TypeAdapter { *; }
-keep class **$$HiveAdapter { *; }
-keep @interface hive.HiveType
-keep @hive.HiveType class * { *; }
-keepclassmembers class * {
    @hive.HiveField *;
}

# -----------------------------------------------------------------------------
# Kotlin metadata + coroutines
# -----------------------------------------------------------------------------
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-dontwarn kotlinx.coroutines.**

# -----------------------------------------------------------------------------
# Keep annotations, signatures, line numbers for crash symbolication
# -----------------------------------------------------------------------------
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# -----------------------------------------------------------------------------
# JSR-305 / nullability annotations referenced by libraries
# -----------------------------------------------------------------------------
-dontwarn javax.annotation.**
-dontwarn org.jetbrains.annotations.**
