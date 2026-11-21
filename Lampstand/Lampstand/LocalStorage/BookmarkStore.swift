import Foundation
import Combine
import SwiftUI

/// A verse saved by the reader for later reference.
///
/// A bookmark is uniquely identified by Bible version, canonical book name,
/// chapter, and verse. This prevents the same verse from being added more than
/// once while allowing identical references from different Bible versions.
struct BibleBookmark: Codable, Identifiable, Equatable {
    /// Stable key in the form `version|book|chapter|verse`.
    var id: String
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
    let version: String
    let createdAt: Date

    init(book: String, chapter: Int, verse: Int, text: String, version: String, createdAt: Date = Date()) {
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.version = version
        self.createdAt = createdAt
        self.id = Self.makeID(book: book, chapter: chapter, verse: verse, version: version)
    }

    /// Creates the stable local identifier for a bookmark.
    static func makeID(book: String, chapter: Int, verse: Int, version: String) -> String {
        "\(version.lowercased())|\(book.lowercased())|\(chapter)|\(verse)"
    }
}

/// Manages bookmarks using on-device `UserDefaults` persistence.
///
/// This store:
/// - Loads encoded bookmarks when it is initialized.
/// - Publishes changes immediately for SwiftUI.
/// - Stores newest bookmarks first.
/// - Adds a bookmark only when its stable identity is not already present.
/// - Removes a bookmark through swipe/delete or a verse bookmark button.
/// - Never sends bookmark data to the network or any remote service.
@MainActor
final class BookmarkStore: ObservableObject {
    /// Shared store used throughout the app.
    static let shared = BookmarkStore()

    /// The current locally persisted bookmark collection.
    @Published private(set) var bookmarks: [BibleBookmark] = []

    private let defaults: UserDefaults
    private let storageKey = "lampstand.bookmarks"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        bookmarks = Self.decode(from: defaults, key: storageKey)
    }

    /// Returns whether a reference is currently bookmarked in the requested version.
    func isBookmarked(book: String, chapter: Int, verse: Int, version: String) -> Bool {
        let id = BibleBookmark.makeID(book: book, chapter: chapter, verse: verse, version: version)
        return bookmarks.contains(where: { $0.id == id })
    }

    /// Adds or removes a bookmark, then persists the updated collection locally.
    func toggle(_ bookmark: BibleBookmark) {
        if bookmarks.contains(where: { $0.id == bookmark.id }) {
            remove(bookmark)
        } else {
            bookmarks.insert(bookmark, at: 0)
            persist()
        }
    }

    /// Removes one bookmark from memory and `UserDefaults`.
    func remove(_ bookmark: BibleBookmark) {
        bookmarks.removeAll(where: { $0.id == bookmark.id })
        persist()
    }

    /// Removes bookmarks selected by a SwiftUI `List` delete gesture.
    func remove(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        persist()
    }

    /// Encodes the full bookmark collection as JSON and writes it to local preferences.
    private func persist() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            defaults.set(data, forKey: storageKey)
        }
    }

    /// Decodes the locally stored bookmark collection, returning an empty array if
    /// the key is missing or the saved data is invalid.
    private static func decode(from defaults: UserDefaults, key: String) -> [BibleBookmark] {
        guard let data = defaults.data(forKey: key),
              let bookmarks = try? JSONDecoder().decode([BibleBookmark].self, from: data) else {
            return []
        }
        return bookmarks
    }
}
