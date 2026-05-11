# LocalLend

**Tiebe Vaes & Natalia Kowal — Groep 17**

LocalLend is a peer-to-peer rental app that lets neighbours lend household
appliances and tools to each other. Owners list items with a description,
category, photo, price and a per-day availability calendar; renters browse
nearby items on a list or map, book the days they need, and leave reviews
afterwards. Built with Flutter + Riverpod, backed by Firebase (Auth +
Firestore), with Google Maps and Places for location features.

---

## Features

### Auth & profile
- Email/password sign-up and sign-in (Firebase Auth).
- Profile document mirrored to Firestore with display name, last-known
  coordinates, and favourite item ids.
- Router redirects unauthenticated users to the login screen.

### Browsing
- **Home** — grid of every available item, with:
  - Free-text search.
  - Category chips (Kitchen, Garden, Cleaning, Tools, Electronics, Other).
  - Distance slider (1–50 km) measured against the user's location.
- **Map** — full-screen Google Map with one marker per available item; tap a
  marker for a floating preview that opens the detail screen.
- **Favourites** — heart any item from its detail page; favourites get their
  own tab.

### Listing an item
- Pick a photo from the gallery or camera. The image is resized (1024 px,
  q70) and stored inline as base64 — Firestore-doc-size-safe (≤ 900 KB).
- Address autocomplete via Google Places, or one-tap "Use current location"
  with reverse-geocoding.
- Per-day availability picker — toggle any combination of days (not just a
  range). Per-month bulk select/clear shortcuts included.
- Title, description, category, price-per-day are required.

### Booking
- Calendar view of the item's availability, with conflicts and past/today
  blocked out (earliest start = tomorrow).
- Days outside the owner's availability list are also blocked.
- Multi-day range selection.
- `createBooking` runs in a Firestore transaction with an
  `arrayContainsAny` overlap check, so two renters cannot claim the same day.
- Total price is computed live; bookings are recorded with `dayKeys` for fast
  conflict queries.

### After booking
- Local notification scheduled 12 h before the rental ends.
- Item-detail "Rent now" button is **owner-aware** + **live**:
  - shows *Your listing* if you own the item,
  - *Unavailable* when the owner toggled it off,
  - *Currently rented* when an active booking covers today,
  - *Rent now* otherwise.
- Cancelled bookings free their days again immediately.

### Reviews
- 5-star rating + free text, scoped to one item.
- Visible to anyone who opens the item detail.

### Dashboard
- **My rentals** — grouped by Active / Upcoming / Past / Cancelled. Each row
  has a Cancel button (with confirmation) for upcoming + active bookings.
- **My listings** — per-listing availability toggle and quick link to the
  detail screen.
- **Reseed demo data** button (top-right) wipes items/bookings/reviews/meta
  and writes the 10 seed items again. Useful when demoing.

### Real-time sync
- Every Firestore read is a `StreamProvider`, so listing/booking/cancelling on
  one device pushes to all others within ≈1 s.

## Tech stack

| Layer            | Choice                                     |
|------------------|--------------------------------------------|
| Framework        | Flutter (Dart 3.11+)                       |
| State management | Riverpod                                   |
| Navigation       | go_router (StatefulShellRoute for tabs)    |
| Backend          | Firebase Auth, Cloud Firestore             |
| Maps & places    | google_maps_flutter, Google Places API     |
| Notifications    | flutter_local_notifications                |
| Configuration    | flutter_dotenv (`.env`)                    |
| Image picker     | image_picker (stored inline as base64)     |

## Project structure

```
lib/
  app.dart                  Root widget + theming
  main.dart                 Entry point: env + Firebase + seed
  core/                     Theme, router, utils, config, maps loader
  models/                   AppUser, Item, Booking, Review
  providers/                Riverpod providers
  repositories/             Firestore data access (Auth, Item, Booking, Review)
  services/                 Notifications, Places, demo seeder
  widgets/                  Reusable UI (cards, fields, image, etc.)
  screens/
    auth/                   Login, register
    home/                   Browsing
    map/                    Map view of all items
    favorites/              Favourite items
    add_item/               Listing flow (form + availability picker)
    item_detail/            Detail + booking calendar
    dashboard/              My rentals + my listings + reseed
    shell/                  Bottom-nav shell
```

## Getting started

### Prerequisites

- Flutter SDK 3.11 or newer
- A Firebase project with Auth (Email/Password) + Firestore enabled
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

The Maps key in `.env` is read at runtime for web (`maps_loader_web.dart`)
and for the Places/Geocoding REST calls on mobile. The Android Maps SDK key
is injected from the same `.env` into `AndroidManifest.xml` via Gradle
`manifestPlaceholders` — never commit it to source.

### Install and run

```bash
flutter pub get
flutter run
```

To target a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

### Build

```bash
flutter build apk --release    # Android
flutter build web --release    # Web
```

## Testing real-time sync with two tabs

The streaming behaviour is easiest to demo by running two clients side by
side, each signed in to a different account.

### Option A — two Chrome windows (recommended)

Run each on a different web port so they don't clash:

```bash
# Terminal 1
flutter run -d chrome --web-port=5000

# Terminal 2 (new window)
flutter run -d chrome --web-port=5001
```

To avoid Chrome sharing the Firebase Auth session between tabs, launch the
second one in incognito:

```bash
flutter run -d chrome --web-port=5001 --web-browser-flag="--incognito"
```

### Option B — two Android emulators

In Android Studio's **Device Manager**, start two emulators (clone the AVD
if you only have one). Then in two terminals:

```bash
flutter devices
flutter run -d emulator-5554
flutter run -d emulator-5556
```

### Option C — emulator + physical phone

Plug in a USB-debugging-enabled phone, list devices, run one instance per
device id.

### Demo script

1. Sign up `owner@test.com` on tab 1 and `renter@test.com` on tab 2.
2. **Owner** taps the **+** tab and lists an item (photo, address,
   availability picker — pick several non-consecutive days).
3. **Renter** sees the new item appear instantly in Home and on the Map.
4. **Renter** taps the item → *Rent now* → selects two of the available
   days → *Place order*.
5. **Owner** sees the booking show up in **Dashboard → My rentals/listings**
   immediately; the calendar in the renter's view now blocks those days.
6. **Renter** cancels the booking from the dashboard → the days free up
   again and *Rent now* re-enables on both tabs.
7. **Owner** uses the *Reseed* button (top-right of Dashboard) to restore
   the demo dataset between runs.

## Architecture notes

- **Repositories** wrap Firestore collections and expose `Stream`-based APIs.
- **Riverpod providers** in `lib/providers/providers.dart` compose
  repositories and derive state (filtered items, auth state, etc.).
- **PlacesService** has two implementations selected via conditional
  imports: HTTP on mobile/desktop, the `google.maps.places` JS library on
  web (avoids CORS).
- **Bookings** store an explicit list of `days` plus `dayKeys` for fast
  `arrayContainsAny` conflict queries; cancelled bookings are excluded from
  the blocked set, so cancelling frees the slots again.
- **Images** are stored inline as base64 strings on the item document. The
  picker enforces a < 900 KB encoded size to stay inside Firestore's 1 MB
  document limit.

## What's mocked

- **Payments** — bookings only create a Firestore doc; no Stripe/PSP.
- **Notifications** — local only, scheduled 12 h before the last booked day.
- **Storage** — Firebase Storage isn't used; images live in the Firestore
  document as base64.

## Authors

- Tiebe Vaes
- Natalia Kowal

Groep 17 — Introduction to Mobile Development
