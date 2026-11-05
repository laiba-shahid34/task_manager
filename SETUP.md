# Dreamy Task Manager - Setup (Windows)

## 0. Pehle ye (sirf ek baar) - build error se bachne ke liye
Environment Variables mein `PUB_CACHE` ko `C:\PubCache` kar dein (ya wo variable hata dein),
taake pub cache aur project dono C: drive par hon. Phir naya terminal kholein.
`android/gradle.properties` mein ye line bhi rakhein:
    kotlin.incremental=false

## 1. Files copy karein
Is zip ka content apne project `task_manager` mein copy karein (merge/replace):
- `lib/`      -> purani `lib/main.dart` delete karke ye poora folder rakhein
- `assets/`   -> project root mein
- `android/`  -> project root mein merge (sirf `res/raw` wali files add hongi)

## 2. Packages
    flutter pub remove flutter_timezone
    flutter pub add provider sqflite path intl timezone flutter_local_notifications audioplayers share_plus pdf

## 3. pubspec.yaml mein assets add karein
`flutter:` section ke andar (2 spaces indentation bilkul sahi rakhein):

    flutter:
      uses-material-design: true
      assets:
        - assets/music/
        - assets/sounds/

## 4. Pehle jaisa hi (agar pehle kar chuki hain to dobara nahi)
- `android/app/build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring(...)`
- `AndroidManifest.xml`: notification permissions + 2 receivers

## 5. Run (real phone par)
    flutter clean
    flutter pub get
    flutter run -d <phone-id>
