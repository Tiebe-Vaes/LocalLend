# LocalLend — setup

A peer-to-peer appliance-lending app built with Flutter + Riverpod + Firebase.

## One-time setup

```bash
flutter pub get
```

### 1. Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pick/create a Firebase project and select **Android** only. This rewrites
`lib/firebase_options.dart` and drops `android/app/google-services.json` in place.

In the Firebase console, enable:
- **Authentication → Email/Password**
- **Firestore Database** (start in test mode for the demo)
- **Storage** (start in test mode)

### 2. Google Maps

1. In Google Cloud Console, enable **Maps SDK for Android** on the same project.
2. Create an API key.
3. Replace `REPLACE_ME_MAPS_KEY` in
   `android/app/src/main/AndroidManifest.xml` with the real key.

### 3. Run

```bash
flutter run
```

On first launch the `SeedService` populates 5 sample items (once) so the
browse grid isn't empty. Delete the `meta/seeded_v1` doc in Firestore to
re-seed.

## Architecture

```
lib/
├── core/           theme, constants, utils, router
├── models/         Firestore-mapped data classes
├── repositories/   thin wrappers around Firebase SDKs
├── providers/      Riverpod providers (state + streams)
├── services/       notifications, demo seeder
├── screens/        one folder per feature
└── widgets/        reusable UI components
```

- **State**: Riverpod — `StreamProvider` for Firestore, `StateNotifier` for
  the browse filter.
- **Navigation**: `go_router` with `StatefulShellRoute` for the bottom tabs.
- **Auth gate**: `routerProvider` redirects on auth state changes.

## What's mocked

- **Payments** — booking just writes a `bookings` doc; no Stripe etc.
- **Notifications** — local only, scheduled 12 h before the last booked day.
