# AGENTS.md

RealWorth ("Property Evaluation") — Flutter app for real-estate listing creation, backed by a local ASP.NET API. Android application id and iOS bundle id are `com.realworth.app`.

## Commands

- `flutter analyze` — lint/analyze (clean; run before finishing changes)
- `flutter test` — full suite (182 tests, all pass); no single-test runner needed, tests are fast
- `flutter run` — dev app; requires the backend to be running (below)

There is no CI, no custom scripts, no codegen. `analysis_options.yaml` is stock `flutter_lints`; keep it that way unless asked.

## Backend dependency (critical)

The app is useless without the local .NET backend. Source lives in a **separate repo**: `C:\Users\dylan\source\repos\realestate_api` (path recorded in the gitignored `API_source_code.md`).

- Base URL is platform-dependent, set in `lib/core/constants/api_constants.dart`:
  - Android emulator: `https://10.0.2.2:7063`
  - Desktop: `https://localhost:7063`
- Dev HTTPS uses self-signed certs: `ApiClient` (`lib/core/network/api_client.dart:38`) disables certificate validation via `badCertificateCallback`. Do NOT "fix" this — the backend runs on a self-signed dev cert. `Image.network` uses its own client, so `main.dart` also installs `allowApiImagesWithDevCert` (an `HttpOverrides` that accepts the bad cert **only for the API host**); without it every server photo shows "Unavailable".
- Photo paths: only `http(s)://…` and `/uploads/…` are server photos (`isRemotePhoto`). Device paths also start with `/` — never treat a bare `/` as remote.
- All endpoints are under `/api/...`; see `lib/core/network/api_endpoints.dart`.

## Platform scope

`api_client.dart` imports `dart:io`, so the `web/` scaffold does **not** compile. Mobile/desktop only.

## Architecture

Feature-first: each feature under `lib/features/<feature>/` has `data/`, `presentation/`, `providers/`. Shared code lives in `lib/core/` (`network`, `router`, `theme`, `constants`, `errors`, `widgets`). Add new features following this shape.

- **State**: Riverpod v3 (`Notifier`/`NotifierProvider`, `autoDispose` where appropriate). Providers per feature in `providers/`.
- **Routing**: go_router via `appRouterProvider` (`lib/core/router/app_router.dart`). `StatefulShellRoute.indexedStack` hosts Home + Settings (bottom nav); property-wizard screens are flat routes with `parentNavigatorKey: _rootNavigatorKey`.
- **Auth**: JWT + refresh token stored in `flutter_secure_storage` under key `auth` (`AppConstants.storageAuthKey`). `ApiClient` interceptors auto-refresh on 401 and retry; the router redirect gated on `authProvider` status. Login accepts an email or a username (registration stores the lowercased email as the username). Password reset is an emailed 6-digit code (`/forgot-password`, `POST /api/auth/forgot-password` + `/reset-password`).
- **Agent profile**: `agentProfileProvider` loads `GET /api/agents/me` whenever the agent becomes signed in and saves via `PUT`; the secure-storage copy is only a cache (it also keeps the first/last-name split — the API stores one display name).
- **Theme**: brand themes via `RealEstateTheme` factories in `lib/core/theme/themes.dart`, selected at runtime through `theme_provider.dart`.

## Property wizard conventions

- Non-linear overview flow: one shared `PropertyState` + `PropertyViewModel` (autoDispose `Notifier`, `lib/features/property_overview/providers/property_provider.dart`) holds all section data; each section screen calls a `save*` method that persists that section to the backend independently.
- **Saving is explicit.** Section screens wrap their body in `WizardSectionScaffold` (`presentation/widgets/wizard_section_scaffold.dart`), which pins a Save button to the bottom and commits via `onSave`. Backing out never persists: the scaffold snapshots the shared state on entry (`beginSectionEdit`) and restores it on discard (`discardSectionEdit`), confirming first when something changed. Use this scaffold for new wizard screens rather than hand-rolling `PopScope`. (This replaces the previous auto-save-on-back behaviour.)
- Any screen with a primary action pins it to the bottom (`bottomNavigationBar` + `SafeArea(top: false)`) rather than placing it inline at the end of a scroll view.
- Pickers with more than a handful of options use `showSearchablePicker` (`core/widgets/searchable_picker.dart`) — a type-to-filter bottom sheet — not a dedicated screen or a wall of chips. All bottom sheets go through `showRealEstateBottomSheet`, which applies safe-area, keyboard-inset and max-height handling.
- Models are plain Dart classes with `fromJson`/`toJson`; enums live under `data/models/enums/`.
- `PropertyType` ordinal position is the backend id (index + 1) — do not reorder or insert entries. Slot 4 reads "Commercial Property" while the database still seeds it as "Vacant Land"; see `docs/BACKEND_CHANGES.md`.
- Reference/lookup data (property types, features, etc.) is fetched via `ReferenceDataProvider` / `LookupApiService`.
- New rooms start with **nothing ticked**. Which amenities a room offers is `StandardAmenity.relevantForCategory`; whole-house items (alarm, CCTV, fibre) are never offered per room. Amenity `displayString`s are matched by name against the API's feature lookup — do not reword existing ones.
- Section completeness (`isAddressComplete`, `isOwnerComplete`, …) and the house score live on `PropertyState`, so the overview and each screen's validation agree.
- Discard prompts compare **content** (`PropertyState.sameContentAs`), never object identity. A listing left with nothing captured (`hasMeaningfulContent`) is deleted on leaving the overview (`discardIfEmpty`), and only when it was fully loaded.
- Each room has a 0–10 `score` (slider at the end of the room), stored in `Condition.Score`, and up to 20 photos (`Room.photos`, first = cover; `/rooms/{id}/photos`).
- **Photos** (property and room) use `ReorderablePhotoStrip` / `pickPhotos` (`presentation/widgets/photo_strip.dart`): gallery multi-select up to 20, hold-and-drag to reorder, tap for "make main/cover" or remove. The first photo is the main (property) or cover (room). Order is saved with `PUT /api/listings/{id}/photos/order` (immediately, once every photo is uploaded) and `PUT …/rooms/{roomId}/photos/order` (on the Property Features save). Photos not yet uploaded exist only in memory: leaving the property warns first (`pendingPhotoCount`).
- **Room condition** is the single-choice `ConditionScale` (`presentation/widgets/condition_scale.dart`): six bands worst→best, each with its own icon and red → orange → grey → green colour (`ConditionRatingStyle`).
- **House score** is a percentage saved on the listing (`PUT /api/listings/{id}/house-score`). The app suggests a *weighted* average of room scores (`RoomScore.weightFor` — kitchens, main bedrooms, bathrooms count more) and saves it after Property Features; once the agent sets their own (`houseScoreIsManual`) the suggestion no longer overwrites it.
- Property Features is complete when there is ≥1 room and every room has a condition rating or a score.
- **Country & currency** (`lib/core/locale/`): `regionProvider` holds the agent's country and currency (device-local, default South Africa); Settings picks each, registration sets both. `country_data.dart` is **generated** from CLDR + libphonenumber — regenerate, don't hand-edit. Phone fields use `CountryPhone` + `PhonePrefix` (flag + dial code); money fields use `CurrencyPrefix` and `regionProvider.currencySymbol` — never hardcode "R"/"ZAR". The SA ID format only applies when the country is South Africa.
- **SA formats** (`lib/core/validation/sa_formats.dart`): ID numbers (13 digits, YYMMDD date, citizenship digit 0/1, Luhn check; shown `YYMMDD GGGG CCC`) and phone numbers (fixed `+27` prefix via `SaPhonePrefix`, 9 digits shown `82 123 4567`, stored `+27…`). Entry uses `GroupedDigitsFormatter` — digits only, spaces inserted automatically. Owner validation is `validateContact`.
- **Keyboards:** `CustomTextInput` picks capitalisation from the keyboard type (plain text → sentence case, `TextInputType.name` → words, email/number/phone/password → none); set `keyboardType` correctly and override `textCapitalization` only when needed (e.g. `characters` for licence numbers, `TextInputType.datetime` for `2021/123456/07` registration numbers). Password fields must set `isPassword: true`: it forces no capitalisation, autocorrect or suggestions even while the password is shown (the eye icon sets `obscureText: false`).
- **Home:** Active/Archived tabs; swipe a card to archive/restore (`PUT /api/listings/{id}/archive`); archived tab has a search over address, all owners and reference; lists are newest first. Leave the property screen with `pop()` (`_exitToHome`), not `go()`.
- Multi-pick lists use `showMultiSelectSheet` (`core/widgets/multi_select_sheet.dart`): tick several, confirm once. Parking uses it, then − n + steppers; a type left at 0 is dropped on save.

## White-labelling

Agencies come from the API: `agencyDirectoryProvider` (`lib/core/theme/agency_directory.dart`) loads `GET /api/agencies` (public, so registration works signed out), caches it in `SharedPreferences`, and falls back to the bundled `Agency.all` in `lib/core/theme/agency.dart`. The selected agency is held by `agencyProvider` (slug persisted to `SharedPreferences`), follows server restyles, and drives `themeConfigProvider` via `RealEstateTheme.fromAgency` / `fromAgencyDark`.

- **Adding or restyling an agency is a database change, not an app release**: a row in `dbo.Agencies` plus a logo uploaded to R2 by `tools/SeedAgencyLogos` in the API repo (see its README). `Agency.fromApi` swaps in legible text ink if the colours sent fail contrast.
- Logos: `AgencyLogo` / `agencyLogoImage` draw `logoUrl` (R2), showing the bundled `assets/images/agencies/<slug>.png` while it loads or when offline, then a monogram tile. Bundled files and `Agency.all` are only the offline fallback now.
- Agents can add an unlisted agency ("Other" in `showAgencyPicker`) with an optional logo. It is posted to the API and shared with every agent (house palette, logo on white). If the API cannot take it (offline, or during registration before the account exists) it is kept on the device (`customAgenciesProvider`) and `syncLocalAgencies` sends it up at the next sign-in.
- Login, register and password reset always use the house theme (`houseThemeProvider` + `ScopedBrandTheme`), never the selected agency's.
- The profile screen previews a newly picked agency locally; `agencyProvider` only changes on Save.

## Known backend gaps

`docs/BACKEND_CHANGES.md` lists what the app needs from `realestate_api` but cannot do locally — listings are not scoped per agent, agent profiles have no read/update endpoint, and there is no listing-level photo upload. Features depending on those are built but device-local; read it before assuming one of them is an app bug.

## Tests

- Unit tests in `test/unit/`, widget tests in `test/widgets/`.
- No mocking framework is used; network-touching providers are not unit-tested. Widget tests only exercise UI that renders without backend calls (e.g. login screen when unauthenticated).
