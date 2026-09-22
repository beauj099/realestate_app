# AGENTS.md

RealWorth ("Property Evaluation") — Flutter app for real-estate listing creation, backed by a local ASP.NET API. Android application id and iOS bundle id are `com.realworth.app`.

## Commands

- `flutter analyze` — lint/analyze (clean; run before finishing changes)
- `flutter test` — full suite (35 tests, all pass); no single-test runner needed, tests are fast
- `flutter run` — dev app; requires the backend to be running (below)

There is no CI, no custom scripts, no codegen. `analysis_options.yaml` is stock `flutter_lints`; keep it that way unless asked.

## Backend dependency (critical)

The app is useless without the local .NET backend. Source lives in a **separate repo**: `C:\Users\dylan\source\repos\realestate_api` (path recorded in the gitignored `API_source_code.md`).

- Base URL is platform-dependent, set in `lib/core/constants/api_constants.dart`:
  - Android emulator: `https://10.0.2.2:7063`
  - Desktop: `https://localhost:7063`
- Dev HTTPS uses self-signed certs: `ApiClient` (`lib/core/network/api_client.dart:38`) disables certificate validation via `badCertificateCallback`. Do NOT "fix" this — the backend runs on a self-signed dev cert.
- All endpoints are under `/api/...`; see `lib/core/network/api_endpoints.dart`.

## Platform scope

`api_client.dart` imports `dart:io`, so the `web/` scaffold does **not** compile. Mobile/desktop only.

## Architecture

Feature-first: each feature under `lib/features/<feature>/` has `data/`, `presentation/`, `providers/`. Shared code lives in `lib/core/` (`network`, `router`, `theme`, `constants`, `errors`, `widgets`). Add new features following this shape.

- **State**: Riverpod v3 (`Notifier`/`NotifierProvider`, `autoDispose` where appropriate). Providers per feature in `providers/`.
- **Routing**: go_router via `appRouterProvider` (`lib/core/router/app_router.dart`). `StatefulShellRoute.indexedStack` hosts Home + Settings (bottom nav); property-wizard screens are flat routes with `parentNavigatorKey: _rootNavigatorKey`.
- **Auth**: JWT + refresh token stored in `flutter_secure_storage` under key `auth` (`AppConstants.storageAuthKey`). `ApiClient` interceptors auto-refresh on 401 and retry; the router redirect gated on `authProvider` status.
- **Theme**: brand themes via `RealEstateTheme` factories in `lib/core/theme/themes.dart`, selected at runtime through `theme_provider.dart`.

## Property wizard conventions

- Non-linear overview flow: one shared `PropertyState` + `PropertyViewModel` (autoDispose `Notifier`, `lib/features/property_overview/providers/property_provider.dart`) holds all section data; each section screen calls a `save*` method that persists that section to the backend independently.
- **Saving is explicit.** Section screens wrap their body in `WizardSectionScaffold` (`presentation/widgets/wizard_section_scaffold.dart`), which pins a Save button to the bottom and commits via `onSave`. Backing out never persists: the scaffold snapshots the shared state on entry (`beginSectionEdit`) and restores it on discard (`discardSectionEdit`), confirming first when something changed. Use this scaffold for new wizard screens rather than hand-rolling `PopScope`. (This replaces the previous auto-save-on-back behaviour.)
- Any screen with a primary action pins it to the bottom (`bottomNavigationBar` + `SafeArea(top: false)`) rather than placing it inline at the end of a scroll view.
- Pickers with more than a handful of options use `showSearchablePicker` (`core/widgets/searchable_picker.dart`) — a type-to-filter bottom sheet — not a dedicated screen or a wall of chips. All bottom sheets go through `showRealEstateBottomSheet`, which applies safe-area, keyboard-inset and max-height handling.
- Models are plain Dart classes with `fromJson`/`toJson`; enums live under `data/models/enums/`.
- `PropertyType` ordinal position is the backend id (index + 1) — do not reorder or insert entries. Slot 4 reads "Commercial Property" while the database still seeds it as "Vacant Land"; see `docs/BACKEND_CHANGES.md`.
- Reference/lookup data (property types, features, etc.) is fetched via `ReferenceDataProvider` / `LookupApiService`; `lib/features/property_overview/data/default_features.dart` supplies offline defaults.

## White-labelling

Agencies live in `lib/core/theme/agency.dart`; the selected one is held by `agencyProvider` (persisted to `SharedPreferences`) and drives `themeConfigProvider` via `RealEstateTheme.fromAgency` / `fromAgencyDark`. Logos are optional files at `assets/images/agencies/<slug>.png` — none ship with the repo, and `AgencyLogo` falls back to a monogram tile when one is absent. Adding an agency means one `Agency` entry plus, optionally, a logo file.

## Known backend gaps

`docs/BACKEND_CHANGES.md` lists what the app needs from `realestate_api` but cannot do locally — listings are not scoped per agent, agent profiles have no read/update endpoint, and there is no listing-level photo upload. Features depending on those are built but device-local; read it before assuming one of them is an app bug.

## Tests

- Unit tests in `test/unit/`, widget tests in `test/widgets/`.
- No mocking framework is used; network-touching providers are not unit-tested. Widget tests only exercise UI that renders without backend calls (e.g. login screen when unauthenticated).
