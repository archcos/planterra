# Firebase libraries
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }

# Keep Firestore specific classes
-keep class com.google.firebase.firestore.** { *; }

# Keep Firebase Auth specific classes
-keep class com.google.firebase.auth.** { *; }

# Keep Google Sign-In classes
-keep class com.google.android.gms.auth.api.signin.** { *; }

# Keep Image Picker
-keep class com.github.dhaval2404.imagepicker.** { *; }

# Keep Flutter related classes
-keep class io.flutter.** { *; }

# Keep all Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
   static android.os.Parcelable$Creator *;
}

# Keep Play Core split install classes and related methods
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Keep classes that implement Play Store deferred components
-keep class io.flutter.app.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }


# Keep any classes related to reflection (important for some libraries that use reflection)
-keep class * extends java.lang.reflect.** { *; }


# Suppress warnings for missing Play Core classes during R8 shrinking
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
