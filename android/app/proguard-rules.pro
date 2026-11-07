# Pack remaining classes into the default package so DEX names stay short.
# Play Console's "classes for packing" check stays off without this on AGP 9.0.
-repackageclasses

# Gson field names used when flutter_local_notifications restores scheduled reminders.
-keepattributes Signature
-keepattributes RuntimeVisibleAnnotations
-keepattributes AnnotationDefault

-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

-dontwarn sun.misc.**

# Amazon Appstore is not used on Google Play. Keep R8 from treating it as an entry point
# if the RevenueCat plugin still ships a keep-all rule for it.
-dontwarn com.amazon.**
-dontwarn com.revenuecat.purchases.amazon.**
