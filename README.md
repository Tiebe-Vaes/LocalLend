# LocalLend

**Tiebe Vaes & Natalia Kowal — Groep 17**

LocalLend is a Flutter application for renting and lending household items
between neighbours. Owners list items with a price, location, and category;
renters browse nearby items, view them on a map, book date ranges, and leave
reviews.

---

## Features

- Email/password authentication (Firebase Auth)
- Browse items with category, distance and text-search filters
- Interactive map view of all available items
- Item detail page with photos, address, embedded map, reviews
- Address autocomplete via Google Places when listing an item
- Date-range booking flow with conflict checking
- Favourites
- Renter and owner dashboards
- Local notifications for rentals ending soon

## Tech stack

| Layer            | Choice                                     |
|------------------|--------------------------------------------|
| Framework        | Flutter (Dart 3.11+)                       |
| State management | Riverpod                                   |
| Navigation       | go_router                                  |
| Backend          | Firebase Auth, Cloud Firestore             |
| Maps & places    | google_maps_flutter, Google Places API     |
| Notifications    | flutter_local_notifications                |
| Configuration    | flutter_dotenv                             |

## Project structure

```
lib/
  app.dart                  Root widget + theming
  main.dart                 Entry point, env + Firebase init
  core/                     Theme, router, utils, config, maps loader
  models/                   AppUser, Item, Booking, Review
  providers/                Riverpod providers
  repositories/             Firestore data access
  services/                 Notifications, Places, seed data
  widgets/                  Reusable UI components
  screens/
    auth/                   Login, register
    home/                   Browsing
    map/                    Map view of all items
    favorites/              Favourite items
    add_item/               Listing flow
    item_detail/            Detail + booking
    dashboard/              Bookings overview
    shell/                  Bottom-nav shell
```

## Getting started

### Prerequisites

- Flutter SDK 3.11 or newer
- A Firebase project (Auth + Firestore enabled)
- A Google Cloud project with these APIs enabled:
  - Maps SDK for Android
  - Maps JavaScript API (web)
  - Places API
  - Geocoding API

### Configuration

Copy `.env.example` to `.env` and fill in:

```
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
FIREBASE_STORAGE_BUCKET=...
GOOGLE_MAPS_API_KEY=...
ENVIRONMENT=development
```

The Google Maps key is also referenced in
`android/app/src/main/AndroidManifest.xml` and is injected into
`web/index.html` at runtime by `lib/core/maps_loader_web.dart`.

### Install and run

```
flutter pub get
flutter run
```

To target a specific device:

```
flutter devices
flutter run -d <device-id>
```

### Build

```
flutter build apk --release          # Android
flutter build web --release           # Web
```

## Architecture notes

- **Repositories** wrap Firestore collections and expose `Stream`-based APIs.
- **Riverpod providers** in `lib/providers/providers.dart` compose repositories
  and derived state (filtered items, auth state, etc.).
- **PlacesService** has two implementations selected via conditional imports:
  HTTP on mobile/desktop, the `google.maps.places` JS library on web (avoids
  CORS).
- **Bookings** store an explicit list of `days` plus `dayKeys` for fast
  conflict queries (`arrayContainsAny`).

## Authors

- Tiebe Vaes
- Natalia Kowal

Groep 17 — Introduction to Mobile Development
