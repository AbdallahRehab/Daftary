# 009 OCR: google_mlkit_text_recognition references the optional Chinese,
# Devanagari, Japanese and Korean recognizers, but the app only bundles the
# Latin model. Without these, R8 fails the release build on missing classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
