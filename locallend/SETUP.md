# LocalLend — setup

Peer-to-peer appliance-lending app built with Flutter + Riverpod + Firebase.
This file is the short version — see `README.md` for the full feature list
and architecture.

## One-time setup

```bash
flutter pub get
```

### 1. Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pick or create a Firebase project. This rewrites
`lib/firebase_options.dart` and drops `android/app/google-services.json` in
place.

In the Firebase console, enable:

- **Authentication → Email/Password**
- **Firestore Database** (start in test mode for the demo)

Firebase Storage is **not** required — item images are stored inline as
base64 on the Firestore document.

### 2. Environment variables

```bash
cp .env.example .env
```

Fill in:

```
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
FIREBASE_STORAGE_BUCKET=...
GOOGLE_MAPS_API_KEY=...
ENVIRONMENT=development
```

`.env` is git-ignored. The Google Maps key is injected from `.env` into
`AndroidManifest.xml` at build time via Gradle `manifestPlaceholders`, and
loaded at runtime for web + Places/Geocoding on mobile. Never paste the key
directly into the manifest.

### 3. Google Maps / Places

In Google Cloud Console (same project as Firebase or another), enable:

- Maps SDK for Android
- Maps JavaScript API (for web)
- Places API
- Geocoding API

Create an API key and put it in `GOOGLE_MAPS_API_KEY` in `.env`. Restrict
the key by Android package + SHA-1 for release builds.

### 4. Run

```bash
flutter run
```

On first launch, `SeedService` writes 10 sample items in Antwerp (once).
Use the **Reseed demo data** button in the Dashboard (top-right) to wipe
items/bookings/reviews and re-seed.

## Demoing real-time sync (two tabs)

Run two web clients on different ports. The second one in incognito
prevents Firebase Auth from sharing a session via localStorage:

```bash
# Terminal 1
flutter run -d chrome --web-port=5000

# Terminal 2
flutter run -d chrome --web-port=5001 --web-browser-flag="--incognito"
```

Two Android emulators work too:

```bash
flutter devices                       # see ids
flutter run -d emulator-5554
flutter run -d emulator-5556
```

Sign in to a different account in each window, then list an item, book a
range, cancel — every action propagates within ~1 s.

## Architecture

```
lib/
├── core/           theme, constants, utils, router, config, maps loader
├── models/         Firestore-mapped data classes
├── repositories/   thin wrappers around Firebase SDKs
├── providers/      Riverpod providers (state + streams)
├── services/       notifications, Places, demo seeder
├── screens/        one folder per feature
└── widgets/        reusable UI components
```

- **State**: Riverpod — `StreamProvider` for Firestore, `StateNotifier` for
  the browse filter.
- **Navigation**: `go_router` with `StatefulShellRoute` for the bottom tabs.
- **Auth gate**: `routerProvider` redirects on auth state changes.
- **Bookings**: Firestore transaction + `arrayContainsAny` on `dayKeys`
  prevents two renters from booking the same day. Cancelled bookings are
  filtered out so their slots free up again.
- **Images**: picked → resized → base64 → stored inline on the item doc
  (≤ 900 KB enforced to stay under the 1 MB Firestore doc limit).

## What's mocked

- **Payments** — booking just writes a `bookings` doc; no Stripe etc.
- **Notifications** — local only, scheduled 12 h before the last booked day.
- **Storage** — no Firebase Storage; images live as base64 on the item doc.
