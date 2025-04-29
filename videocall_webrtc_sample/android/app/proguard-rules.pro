# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified

# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
# http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}
#-dontusemixedcaseclassnames
#-dontskipnonpubliclibraryclasses
#-verbose
#

##---------------Begin: proguard configuration for Gson  ----------
# Gson uses generic type information stored in a class file when working with fields. Proguard
# removes such information by default, so configure it to keep all of it.
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes Exceptions

# For using GSON @Expose annotation
-keepattributes *Annotation*

#quickblox sdk
-keep class com.quickblox.** { *; }

#smack xmpp library
-keep class org.jxmpp.** { *; }
-keep class org.jivesoftware.** { *; }
-dontwarn org.jivesoftware.**

-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.v1.**

#webrtc
-keep class org.webrtc.** { *; }

#google gms
-keep class com.google.android.gms.** { *; }

#json
-keep class org.json.** { *; }

#flutter file picker library
-keep class androidx.lifecycle.DefaultLifecycleObserver

-keep class com.google.firebase.iid.** { *; }
-keep class java.beans.** { *; }
-keep class org.conscrypt.** { *; }
-keep class org.w3c.dom.bootstrap.** { *; }
-dontwarn com.google.firebase.iid.**
-dontwarn java.beans.**
-dontwarn org.conscrypt.**
-dontwarn org.w3c.dom.bootstrap.**

# Firebase Messaging
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
 -keep class com.hiennv.flutter_callkit_incoming.** { *; }

# QuickBlox
-keep class com.quickblox.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes RuntimeVisibleAnnotations