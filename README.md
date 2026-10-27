# Balincia — Flutter app

The mobile companion to **Balincia**, a perfume and attar store built on Next.js
([balincia.vercel.app](https://balincia.vercel.app)). It uses the same brand (Fraunces and
Manrope on warm paper, ink and gold) and the same 40-scent catalogue, and it ports the
store's business logic to Dart. There is no backend: every flow runs on seeded sample data.

## Features

- **Painted bottles.** `BottleArt` is a `CustomPainter` port of the web store's SVG
  bottles. It draws eight shapes (classic, round, tall, attar, box, diffuser, candle,
  mist) from each product's two-colour palette in the same 400×500 viewBox, with
  liquid and glass gradients, highlight strips, caps, a blurred floor shadow and the
  printed BALINCIA label.
- **Home.** An editorial hero with three floating bottles, a notes marquee, best-seller,
  new-arrival and gift-set rails, collection tiles, scent-family cards and a quiz banner.
- **Shop / collections.** A two-column grid with sorting and a filter bottom sheet for
  gender, scent family, season, occasion, price, longevity, genre and sale items. Filters
  and sorting come from `catalog.ts`: `parseFilters`, `filtersToWhere` and `sortToOrderBy`.
  The virtual collections (Best Sellers, The Oud Edit, Under Rs. 2,000…) and the
  categories open as pre-filtered pages.
- **Search** runs live over names, taglines, notes, families and collections, and
  shows which note matched.
- **Product detail.** A large bottle on its palette backdrop, a size selector with
  sale pricing, a top / heart / base pyramid, longevity and sillage meters, seasons and
  occasions, seeded reviews and related scents.
- **Scent quiz.** Five steps with progress and an editable trail of your answers. Results
  are ranked with `scoreProduct` from `quiz.ts`, shown as a % match against the best
  possible score, with the matching persona.
- **Bag → checkout → confirmation.** Quantity steppers, swipe-to-remove with undo,
  discount codes (WELCOME10, FLAT500, FREESHIP, plus the expired EID25) and Balincia
  Points capped at 20% of the order. A free-delivery meter tracks the Rs. 3,000
  threshold, and Standard or Express shipping is priced by the same `computeTotals` rules
  as `pricing.ts`. Placing an order creates a `BLC-XXXXXX` number, deducts redeemed points,
  records the points it will earn on delivery and empties the bag.
- **Account.** A profile card, a points balance with Silver → Gold → Noir tier progress,
  order history with a status timeline and tracking on each order, buy again, an
  editable address, and boutique and concierge sheets.
- **Wishlist.** Hearts stay in sync across every screen, and "add all to bag" moves
  saved scents into the bag.

## Run

```bash
flutter pub get
flutter run            # any device, or: flutter run -d chrome
flutter test
flutter build web --release --no-web-resources-cdn
```

Every screen can be opened from a URL (path URL strategy), for example
`/shop?filters=1`, `/product/noir-oud-royale`, `/quiz?step=3`, `/quiz/results?demo=1`,
`/bag`, `/checkout`, `/order-confirmed/demo`, `/account` and `/orders/BLC-R4WD8T`.
On the web, adding `shot=1` simulates iPhone safe areas for screenshots, and
`shots.json` lists the portfolio captures.

## Structure

```
lib/
  main.dart            URL strategy, bundled-font warm-up, runApp
  app.dart             MaterialApp.router, theme, screenshot-mode safe areas
  router.dart          go_router: StatefulShellRoute tabs + full-screen routes
  theme.dart           Brand colours, Fraunces/Manrope type scale, Material 3 theme
  data/                products.dart (generated from the web seed), catalog filters,
                       pricing, quiz scoring, reviews, sample account data
  models/              Product/Variant/Category, cart, order, coupon, customer
  state/               ChangeNotifier stores (cart, wishlist, account, quiz) + AppScope
  screens/             Home, Shop, Search, Product, Quiz, Results, Bag, Checkout,
                       Confirmation, Account, Order detail, Wishlist
  widgets/             BottleArt painter, product card/grid, filter sheet, shared UI
assets/google_fonts/   Fraunces + Manrope, bundled so nothing is fetched at runtime
```

The app uses two packages: `go_router` and `google_fonts`. State uses `ChangeNotifier`
with `ListenableBuilder`, provided through an `InheritedWidget`.
