# DailyFlow — setup & build guide

Honest heads-up first: I wrote and reviewed this code carefully, but I do not have Flutter
installed in the environment I work in, so I could not compile or run it myself. Treat this
as a strong first draft — when you `flutter pub get` / `flutter run` for the first time you
may hit one or two small errors (wrong import, a renamed API in a package version), which is
completely normal for a hand-written Flutter project. Paste me the exact error and I'll fix it.

## What this gives you

- **Android**: real reminders that fire even after you've swiped the app away (closed it),
  using Android's own alarm system (`AlarmManager`, via `flutter_local_notifications`), with
  sound + vibration + full-screen alert.
- **Windows**: since a closed Windows app cannot wake itself up (no OS-level equivalent of
  Android's AlarmManager for a fully-closed app), reminders are instead registered as real
  **Windows Task Scheduler** entries — the OS itself plays your sound file and pops a message,
  independent of whether DailyFlow is running. Use the "Sync to Windows Task Scheduler" button
  in Settings after setting up your routine.

## 1. Install Flutter (one-time, on your own PC)

1. Download the Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Unzip it somewhere like `C:\src\flutter`, then add `C:\src\flutter\bin` to your PATH
   (Windows: Settings → search "environment variables" → edit `Path`).
3. Install **Android Studio** (for the Android SDK + emulator/device tools):
   https://developer.android.com/studio
4. Open a new terminal and run:
   ```
   flutter doctor
   ```
   Fix anything it flags with a ✗ (usually: accept Android licenses with
   `flutter doctor --android-licenses`, or install missing Visual Studio C++ workload for
   Windows desktop support).
5. Enable Windows desktop builds:
   ```
   flutter config --enable-windows-desktop
   ```

## 2. Create the project and drop these files in

```
flutter create dailyflow
```
Then **replace** the generated `pubspec.yaml` with the one in this folder, and replace
`lib/main.dart` with the one in this folder. Run:
```
cd dailyflow
flutter pub get
```

## 3. Android manifest edits (required for real background reminders)

Open `android/app/src/main/AndroidManifest.xml` and add these lines inside the
`<manifest>` tag (as siblings of `<application>`, not inside it):

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

`RECEIVE_BOOT_COMPLETED` matters most for you: without it, reminders stop firing after the
phone restarts, until you open the app again.

## 4. Add your own ringtone (Android)

Put an mp3 file at:
```
android/app/src/main/res/raw/alarm.mp3
```
(create the `raw` folder if it doesn't exist). The filename must be exactly `alarm.mp3` — the
code in `main.dart` references `RawResourceAndroidNotificationSound('alarm')`. If you skip
this step, the build will fail on that line — either add the file or temporarily change that
line to `sound: null` to use the default notification sound.

## 5. Windows alert sound

In the app's **Settings** tab, set the "path to a .wav alert sound" field to a real file on
your PC, e.g. `C:\DailyFlow\alarm.wav` (create that folder and put a `.wav` file there — not
mp3; Windows' built-in `SoundPlayer` only plays `.wav`). Then tap **"Sync now (Windows only)"**
whenever you add or change routine blocks/tasks.

## 6. Build

Android APK:
```
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk` — copy this to your phone and install
it (you'll need to allow "install unknown apps" for whichever app you transfer it with).

Windows EXE:
```
flutter build windows
```
Output folder: `build/windows/x64/runner/Release/` — this contains `dailyflow.exe` plus the
DLLs it needs; keep them together and you can zip the whole `Release` folder to move it to
another PC.

## 7. First run on Android

The first time the app opens it will ask for notification permission and exact-alarm
permission — allow both, or reminders silently won't fire. On some phones (Xiaomi, Oppo,
Vivo, Huawei) you also need to manually disable battery optimization for the app
(Settings → Battery → DailyFlow → "No restrictions") or the OS will kill the scheduled alarms
anyway — this is an OEM-specific restriction outside what any app's code can control.

## Known limitations, stated plainly

- This plays the reminder sound **once**, like a normal notification — it does not ring on
  loop until you dismiss it like a phone alarm clock does. Building a true looping alarm
  (with a full lock-screen alarm UI) is a bigger project on top of this — say the word if you
  want that next.
- On Windows, if you never tap "Sync now," reminders only work while the app is open (same as
  the earlier browser version). The Task Scheduler sync is what makes it work while closed.
