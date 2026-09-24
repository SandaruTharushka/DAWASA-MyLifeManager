# Release build shrinking rules for DAWASA.
#
# Flutter, AndroidX and the plugins ship their own consumer rules. Classes
# referenced from AndroidManifest.xml (MainActivity, InstallResultReceiver
# and the notification receivers) are kept automatically.

# Keep line numbers for readable crash stack traces; the source file name
# is replaced to avoid shipping file paths.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
