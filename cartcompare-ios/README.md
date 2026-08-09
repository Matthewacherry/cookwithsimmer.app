# CartCompare — iOS App

Native iOS shell for [CartCompare](https://cookwithsimmer.app/compare), the grocery
price-comparison app. Built with Capacitor 8 (Swift Package Manager — no CocoaPods).

The full web app is bundled in `www/` and runs locally inside the app (works
offline). The "check price" links open in an in-app Safari view so users can
peek at a store's live price and swipe back without leaving the app.

- **App ID:** `app.cookwithsimmer.cartcompare`
- **Name:** CartCompare

## Ship to TestFlight (on your Mac, ~30 min the first time)

Prereqs: a Mac with [Xcode](https://apps.apple.com/app/xcode/id497799835) installed,
logged into your Apple Developer account (Xcode → Settings → Accounts), and
[Node.js](https://nodejs.org).

1. **Get this folder onto the Mac** (clone the repo or unzip the archive), then in
   Terminal, from this folder:
   ```sh
   npm install
   npx cap sync ios
   npx cap open ios      # opens the project in Xcode
   ```
2. **In Xcode**, select the `App` target → *Signing & Capabilities* tab →
   set **Team** to your developer team. Xcode generates the signing profile
   automatically. (Bundle id is already `app.cookwithsimmer.cartcompare`.)
3. **Smoke test**: pick an iPhone simulator (or your plugged-in phone) and press
   ▶ Run. The app should launch straight into CartCompare.
4. **Create the App Store record** (first time only): on
   [App Store Connect](https://appstoreconnect.apple.com) → My Apps → “+” →
   New App → platform iOS, name **CartCompare**, bundle ID
   `app.cookwithsimmer.cartcompare`, any SKU (e.g. `cartcompare1`).
5. **Archive & upload**: in Xcode set the run destination to **Any iOS Device
   (arm64)** → menu *Product → Archive* → when the Organizer window opens,
   **Distribute App → App Store Connect → Upload** (accept defaults).
6. **TestFlight**: back in App Store Connect → your app → *TestFlight* tab.
   The build appears after ~10–30 min of processing. Add yourself (internal
   testing — instant) and invite testers by email or a public link.
   Internal testing needs no review; external tester links get a light
   1–2 day beta review.

## Updating the app

The web app is the source of truth. To ship an update: replace `www/index.html`
(and icons) with the latest version, then `npx cap sync ios`, bump the build
number in Xcode, and repeat Archive → Upload. TestFlight testers get updates
automatically.

## Roadmap (native superpowers, in rough order of value)

- **Clipboard import**: detect a copied cart when the app opens and offer
  one-tap import.
- **Share Extension**: appear in the iOS share sheet so product pages can be
  shared straight into CartCompare from other apps.
- **In-app cart reader**: open amazon.com/target.com in an in-app browser tab,
  let the user log in and view their cart, and read the items/prices directly —
  the zero-copy "pull my live cart" flow.
- **App Store proper**: TestFlight has no bar to clear, but the public App Store
  review (guideline 4.2, minimum functionality) is friendlier once at least one
  of the native features above ships. Recommended order: TestFlight now,
  clipboard + share extension, then public release.
