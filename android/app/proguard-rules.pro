## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Google Play Core (deferred components)
-dontwarn com.google.android.play.core.**

## Google Sign-In / Credential Manager (google_sign_in 7.x)
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.libraries.identity.**

## Supabase / GoTrue / Realtime
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

## SQLite (sqlite3_flutter_libs)
-keep class eu.simonbinder.** { *; }
-keep class org.sqlite.** { *; }

## Sentry
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

## Gson (if used by any dependency)
-keepattributes Signature
-keepattributes *Annotation*

## Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

## Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
