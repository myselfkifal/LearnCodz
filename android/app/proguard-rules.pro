# Notification schedules use Gson reflection; retain model fields and types.
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
