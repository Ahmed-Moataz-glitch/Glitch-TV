# Flutter Wrapper & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core & Deferred Components
-dontwarn com.google.android.play.core.**

# Awesome Video Player / Better Player Plus
-keep class uz.shs.better_player_plus.** { *; }
-keep interface uz.shs.better_player_plus.** { *; }
-keep class com.jhomlala.betterplayer.** { *; }
-keep interface com.jhomlala.betterplayer.** { *; }

# AndroidX Media3 & ExoPlayer
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-keep class androidx.media.** { *; }
-keep interface androidx.media.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keep interface com.google.android.exoplayer2.** { *; }

# Codecs & Extractor Reflection
-keep class androidx.media3.exoplayer.hls.** { *; }
-keep class androidx.media3.exoplayer.dash.** { *; }
-keep class androidx.media3.exoplayer.smoothstreaming.** { *; }
-keep class androidx.media3.extractor.** { *; }
-keep class androidx.media3.decoder.** { *; }
-keep class androidx.media3.datasource.** { *; }
-keep class com.google.android.exoplayer2.source.hls.** { *; }
-keep class com.google.android.exoplayer2.source.dash.** { *; }
-keep class com.google.android.exoplayer2.source.smoothstreaming.** { *; }
-keep class com.google.android.exoplayer2.extractor.** { *; }

# OkHttp, Cronet & Network
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.chromium.net.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-keep class org.chromium.net.** { *; }

# Just Audio & Audio Service
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media.AudioAttributesCompat { *; }

# Radio Player
-keep class me.sithiramunasinghe.flutter.flutter_radio_player.** { *; }

# SWebView / Flutter InAppWebView
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class android.webkit.** { *; }

# Android WorkManager & Lifecycle
-keep class androidx.work.** { *; }
-keep class androidx.lifecycle.** { *; }
