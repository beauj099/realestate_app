# Releasing to Google Play

## Once: the upload key

Google Play signs the app for devices (Play App Signing); you sign each upload with your own
**upload key**. Create it once and keep the file and passwords safe and private: never commit
them, never email them. Losing it means asking Google to reset it.

```powershell
# Anywhere outside the repo, e.g. C:\Keys (keytool comes with Android Studio's JDK):
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
  -keystore C:\Keys\realworth-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (git ignores it):

```properties
storeFile=C:\\Keys\\realworth-upload.jks
storePassword=<the keystore password>
keyAlias=upload
keyPassword=<the key password>
```

Without this file, release builds are signed with the debug key: fine for testing on a phone,
refused by Play.

## Each release

1. Raise the version in `pubspec.yaml`: `version: 1.0.1+2` (the number after `+` must go up for
   every upload).
2. Build. Release builds use the live API (`https://api.realworth.co.za`) by default, never a
   developer's `.env`:

   ```powershell
   flutter build appbundle --release
   ```

   (For a phone test without Play: `flutter build apk --release --split-per-abi`, then install
   `app-arm64-v8a-release.apk`. To point a release at another server, add
   `--dart-define=API_BASE_URL=https://...`.)

   The bundle is `build/app/outputs/bundle/release/app-release.aab`.
3. Play Console → the app → Testing → Internal testing → Create release → upload the `.aab`.
   Internal testing reaches up to 100 testers within minutes, without review; promote to
   production when it is ready.

## Before the first production release

- Privacy policy at `https://realworth.co.za/privacy.html` and account deletion at
  `https://realworth.co.za/delete-account.html` (upload `docs/website/`, fill in the placeholders).
- Data safety form: `docs/website/PLAY_DATA_SAFETY.md`.
- The live API runs the current `realestate_api` with every patch in
  `Infrastructure/Database/Patches` applied (patches first, then the API).
- Store listing: icon (512 × 512), feature graphic (1024 × 500), at least two phone screenshots,
  short and full description.

## Security in release builds

- Only local development addresses (localhost, the emulator's 10.0.2.2, private networks) may
  use a self-signed certificate (`isDevHost`); the live API's certificate is always checked.
- Request logging (which prints the sign-in token) runs in debug builds only.
