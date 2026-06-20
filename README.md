## Lampstand

Lampstand is a small **iOS Bible reader + verse search** app built with **SwiftUI**. It lets you browse a book/chapter, switch Bible versions, quickly search for a specific verse (book + chapter + verse), and keeps reading feeling fast with **cache-first** loading.

### Features

- **Browse**: select a Bible book, move chapter-by-chapter, and read verses in a clean, “paper” themed UI.
- **Search**: jump straight to a verse (book + chapter + verse) and open it in the reader (with a temporary highlight to orient you).
- **Versions**: switch between supported versions (currently `en-asv` and `en-kjv`).
- **Offline-friendly feel**: chapters/verses are cached locally so previously-read content shows instantly.
- **Appearance**: system / light / dark mode (persisted via `@AppStorage`).

### Technologies

- **Language**: Swift
- **UI**: SwiftUI (`NavigationStack`, `List`, `Picker`, sheets, `ContentUnavailableView`)
- **State / Architecture**: MVVM with `ObservableObject` view models
- **Reactivity**: Combine for input pipelines (sanitization, `removeDuplicates`, debounce)
- **Concurrency**: Swift Concurrency (`async/await`, cooperative task cancellation)
- **Networking**: `URLSession` against static JSON files
- **Persistence**: Core Data (lightweight cache; model defined in code)
- **Testing**: XCTest (view model behavior + network layer URL/decoding via `URLProtocol` stubs)

### Implementation notes

#### MVVM: “latest input wins”

The app is centered around two view models:

- **`BibleBrowserViewModel`**: drives the reader (book selection, chapter navigation, version selection).
- **`BookViewModel`**: drives the verse search flow (book + chapter + verse).

Both follow the same pattern:

- **Cache-first rendering**: show cached results immediately (if present), then refresh from the network.
- **Task cancellation for correctness**: each new user action cancels any in-flight request so only the most recent selection can update the UI.
- **Debounced search**: verse search debounces text input to avoid firing a request per keystroke.

#### Networking: resilient decoding over a static dataset

`NetworkManager` fetches JSON from the Bible dataset hosted via a CDN:

- Base path: `https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles`
- URLs are built by **slugifying** book/version inputs (e.g. `"1 Samuel"` → `1-samuel`).
- Decoding is intentionally defensive because payload shapes can vary:
  - Chapters usually decode from `{ "verses": [...] }`, with fallbacks for a few alternate shapes.
  - A verse endpoint may return a plain `Verse` or a small wrapper object.

#### Persistence: Core Data cache, defined in code

Caching is implemented by `CoreDataVerseStore`:

- A single entity (`CachedVerse`) stores: `(version, book, chapter, verse, text, fetchedAt)`.
- A stable **unique key** (`version|book|chapter|verse`) enables cheap upserts and keeps “refresh” operations simple.
- Reads use `viewContext`; writes use a background context and automatically merge into the UI.
- The Core Data schema is created programmatically (`LampstandManagedObjectModel`) instead of shipping a `.xcdatamodeld`.

### Project structure (high level)

- **`Lampstand/Lampstand/LampstandApp.swift`**: app entry point + global tint + persisted appearance
- **`Lampstand/Lampstand/View/`**: SwiftUI screens (`BibleBrowserView`, `SearchBookView`)
- **`Lampstand/Lampstand/ViewModel/`**: view models (`BibleBrowserViewModel`, `BookViewModel`)
- **`Lampstand/Lampstand/NetworkManager/`**: `NetworkManager` + URL building/decoding
- **`Lampstand/Lampstand/LocalStorage/`**: Core Data cache (`PersistenceController`, `VerseStore`, model builder)
- **`Lampstand/LampstandTests/`**: unit tests for view models and networking behavior

### Requirements

- **Xcode**: 16 or later (Swift 6 concurrency settings)
- **Minimum iOS**: 17.0 (iPhone and iPad)

The app uses SwiftUI APIs introduced in iOS 17 (`ContentUnavailableView`, two-value `onChange`) plus iOS 16 navigation/toolbar APIs (`NavigationStack`, `scrollContentBackground`, `toolbarBackground`). All targets share a single deployment target of **17.0**.

### Running the app

1. Open `Lampstand/Lampstand.xcodeproj` in Xcode.
2. Select the `Lampstand` scheme.
3. Run on an iOS 17+ Simulator (or a connected device running iOS 17 or later).

To run tests: Product → Test (or `⌘U`).

### Data source / attribution

Lampstand reads Bible JSON data from the [`wldeh/bible-api`](https://github.com/wldeh/bible-api) dataset, served via jsDelivr. This project does not bundle Bible text locally; it fetches and caches content on demand.
