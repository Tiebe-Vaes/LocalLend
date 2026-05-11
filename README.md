# LocalLend

**Tiebe Vaes & Natalia Kowal — Groep 17**

LocalLend is a peer-to-peer rental app that lets neighbours lend household
appliances and tools to each other. Owners list items with a description,
category, photo, price and a per-day availability calendar; renters browse
nearby items on a list or map, book the days they need, and leave reviews
afterwards. Built with Flutter + Riverpod, backed by Firebase (Auth +
Firestore), with Google Maps and Places for location features.

The Flutter project lives in [`locallend/`](./locallend) — see
[`locallend/README.md`](./locallend/README.md) for the full feature list,
setup, and how to demo real-time sync with two browser tabs.

---

## Features at a glance

- Email/password authentication (Firebase Auth).
- Browse items with category, distance and text-search filters.
- Interactive Google Map of every available item.
- Item detail with photo, address, embedded map and reviews.
- Address autocomplete via Google Places + reverse-geocoding from GPS.
- Multi-day per-item availability picker (non-consecutive days supported).
- Booking calendar with transaction-safe conflict checking.
- Owner-aware "Rent now" button (your-listing / unavailable /
  currently-rented / rentable).
- Cancellation frees the slots again live.
- Per-user favourites.
- Renter + owner dashboard with reseed-demo button.
- Local notifications for rentals ending soon.
- Real-time sync — Firestore streams push updates to every client.

## Tech stack

| Layer            | Choice                                     |
|------------------|--------------------------------------------|
| Framework        | Flutter (Dart 3.11+)                       |
| State management | Riverpod                                   |
| Navigation       | go_router (StatefulShellRoute)             |
| Backend          | Firebase Auth, Cloud Firestore             |
| Maps & places    | google_maps_flutter, Google Places API     |
| Notifications    | flutter_local_notifications                |
| Configuration    | flutter_dotenv                             |

## Quick start

```bash
cd locallend
cp .env.example .env        # fill in Firebase + Google Maps keys
flutter pub get
flutter run
```

## Demoing real-time sync (two tabs)

Two web clients on different ports, one of them incognito so they don't
share the Firebase Auth session:

```bash
# Terminal 1
flutter run -d chrome --web-port=5000

# Terminal 2
flutter run -d chrome --web-port=5001 --web-browser-flag="--incognito"
```

Sign in as two different accounts → list, book, cancel — each action shows
up in the other window within ~1 s.

Full demo script + alternative setups (two emulators, emulator + phone)
are in [`locallend/README.md`](./locallend/README.md#testing-real-time-sync-with-two-tabs).

## Authors

- Tiebe Vaes
- Natalia Kowal

Groep 17 — Introduction to Mobile Development
