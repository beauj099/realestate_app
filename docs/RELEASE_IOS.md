# Releasing to iPhone (TestFlight and the App Store)

An iPhone app can only be built on a Mac. Codemagic builds it on its own Macs from this
repository (`codemagic.yaml`) and uploads it to Apple, so everything below is done from a
browser on Windows.

## Once

1. **Apple Developer Program** (developer.apple.com/programs, about US$99 a year). As an
   individual it is approved in a day or two; as a company it first needs a D-U-N-S number.
2. **The app in App Store Connect** (appstoreconnect.apple.com → Apps → +, New App):
   platform iOS, name RealWorth, bundle ID `com.realworth.app` (register it first under
   Certificates, Identifiers & Profiles → Identifiers if it is not offered), SKU e.g.
   `realworth-ios`. Copy the app's **Apple ID** (a number, under App Information) into
   `APP_STORE_APPLE_ID` in `codemagic.yaml`.
3. **An API key for Codemagic**: App Store Connect → Users and Access → Integrations →
   App Store Connect API → +, access **App Manager**. Download the `.p8` file (only once
   possible) and note the Issuer ID and Key ID. Keep the file private; never commit it.
4. **Codemagic** (codemagic.io, sign in with GitHub):
   - Team settings → Integrations → Developer Portal → Connect: name it **RealWorth** (the
     name `codemagic.yaml` uses), and give it the Issuer ID, Key ID and `.p8` file.
   - Optional: Team settings → Global variables → group `realworth`, variable `MAPTILER_KEY`
     (the pin map's satellite view), and add the group to the workflow.
   - Add application → GitHub → `beauj099/realestate_app` → Flutter App, and choose
     `codemagic.yaml` as the configuration.
   - Codemagic signing: with the integration in place it creates the distribution
     certificate and profile itself (`ios_signing` in the yaml). If it asks, let it
     generate a new certificate.
5. **Testers**: App Store Connect → the app → TestFlight → Internal Testing → add a group
   and its people. Internal testers must first be added to the team (Users and Access) with
   any role; they get every build without Apple's review. Outside testers (External Testing,
   by email or public link) need a short beta review on the first build.

## Each build

1. Raise the version in `pubspec.yaml` when it is a new release (`1.0.1+…`). The build
   number is set by Codemagic (one more than the last on TestFlight).
2. Push to `master` on GitHub.
3. Codemagic → the app → Start new build → workflow **ios-testflight**. About 15–25 minutes:
   tests, build, upload. Apple then processes the build (up to an hour) and TestFlight
   offers it to the testers, who install it with Apple's **TestFlight** app.

## For the App Store itself

App Store Connect → the app → the version page: screenshots (6.7" and 6.5" iPhone; the app
is iPhone only, so no iPad screenshots), description, keywords, support URL, the privacy
policy URL (`docs/website/privacy.html` once hosted), the App Privacy answers (the same
facts as `docs/website/PLAY_DATA_SAFETY.md`), and **a demo login with a sample listing**
for Apple's reviewer (the app needs an account). Then pick the TestFlight build and Submit
for Review: most apps are reviewed within a day or two.

Notes:

- Release builds use the live API (`https://api.realworth.co.za`); `.env` is only for
  development and Codemagic writes a placeholder one.
- The permission texts Apple shows (camera, photos, location) are in `ios/Runner/Info.plist`;
  keep them accurate, as reviewers check them against what the app does.
- `ITSAppUsesNonExemptEncryption` is false (the app only uses HTTPS), which answers Apple's
  export-compliance question for every upload.
