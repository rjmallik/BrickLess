# BrickLess — App Store checklist

Last updated: Nov 13, 2026. Code is on `main` at rjmallik/BrickLess. Firebase project is now **brickless-1ab80** (free Spark plan, no billing). The old project brickless-6e0f9 was never under RJ's Google account and is abandoned.

## Already done in code

- Real accounts: Firebase Auth email + username/password, unique usernames, mandatory profile setup, in-app Delete Account (Guideline 5.1.1(v)).
- Safety: username/display-name filter, Block and Report, reports stored for console review (Guideline 1.2). Support contact in My Profile: rutujit97872@gmail.com.
- Scale: community courts are fetched by ~1 km grid cell around the user, never the whole collection. Friends search is capped at 20 results. Map calls are cached per grid cell. No analytics, no ads, no tracking.
- Rules fixes (Nov 8): Delete Account can now actually delete the profile doc (it was blocked, which left the username reserved forever), and the booking overlap check can read other players' confirmed bookings for the same court (it silently saw nothing before, so double-bookings were possible). Booking docs hold only user IDs, court IDs and times.
- Indexes: `firestore.indexes.json` has the composite indexes for My Bookings and the overlap check and the friends lists. Deploy with the rules (below); indexes take a few minutes to build the first time.
- App icon: `AppIcon.appiconset` has the 1024x1024 image, which is what the App Store needs.
- Privacy policy: live at https://rjmallik.github.io/brickless-privacy.html (since Nov 9, 2026) — use this URL in App Store Connect. `PRIVACY.md` in this repo matches it.
- No IAP needed: paid real-world court bookings must use Stripe/Apple Pay, never Apple IAP (Guideline 3.1.5(a)); there is no Premium subscription anymore.

## Firebase console — done Nov 13, 2026 (project brickless-1ab80)

1. Authentication > Sign-in method > **Email/Password** is enabled. Verified live: a test sign-up returned an idToken.
2. Firestore Database exists (production mode, nam5/US). Rules + indexes are being deployed (Nov 13); until they land, the database denies everything by default, so sign-up works but friends, courts and bookings fail at runtime.
3. The app's `GoogleService-Info.plist` now points at brickless-1ab80 (commit 906d956). If rules/indexes ever need redeploying from a Mac, in the repo folder: `firebase deploy --only firestore:rules,firestore:indexes` (needs the Firebase CLI: `npm install -g firebase-tools`, then `firebase login`).

## RJ: Xcode + App Store Connect

1. **Apple Developer Program** ($99/year) at developer.apple.com, if you don't have it yet.
2. In Xcode, pick your **signing team** for the BrickLess target (no team is set yet).
3. Build, then **Product > Archive > Distribute App > App Store Connect**.
4. **TestFlight first** (this is the "downloadable" path before the store): in App Store Connect, the build appears under TestFlight. Internal testers (up to 100) can install it with no review; external testers (up to 10,000) need Beta App Review, usually about a day. Testers install the TestFlight app, accept the invite, and download BrickLess from there.
5. App Store listing: screenshots (6.5" and 5.5" iPhone sizes), description, keywords, support URL, and the **privacy policy URL**: https://rjmallik.github.io/brickless-privacy.html.
6. **App Privacy labels** (App Store Connect > App Privacy): we collect Contact Info (email), User Content (username, profile), Precise Location (only while using the map), and User ID. Data is linked to the user. Data is **not** used for tracking, and nothing is sold. There is no analytics or advertising SDK.
7. **Age rating:** expect 12+ because of user-generated content and friend interaction. Be honest in the questionnaire; the rating follows from it.
8. Submit for review. First review is usually 1-3 days.

## Known limits, honestly

- **No single source lists every court.** OpenStreetMap covers mapped public courts; players add the rest in the app. Unmapped, private, and school courts are missing until someone adds them. OpenStreetMap has no hours, fees, or live availability.
- **Overpass is a shared free service.** At very high usage it can rate-limit. The app still shows community courts when that happens; a backend proxy is the fix if it ever becomes a real problem.
- **Booking race.** The overlap check runs on the phone, so two people booking the same slot in the exact same second could both get through. Rare, acceptable for v1; a server-side check is the later fix.
- **Paid bookings.** Real facilities that charge money can only be booked if the facility offers booking. Most public parks cannot be booked through any API.
