# uCrop (image_cropper) references OkHttp optionally for remote URIs.
# OkHttp is not a required dependency for local image cropping.
-dontwarn okhttp3.**
-dontwarn com.yalantis.ucrop.**
-keep class com.yalantis.ucrop.** { *; }
