//
//  Model.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import Foundation

/// A UI-friendly wrapper around a chapter fetch.
///
/// The network layer fetches raw verses, but the reader UI benefits from having
/// "previous/next chapter" hints computed alongside the verses so navigation can be
/// enabled/disabled without additional logic in the view.
struct ChapterPage {
    let book: String
    let chapter: Int
    let verses: [Verse]
    let previousChapter: Int?
    let nextChapter: Int?
}

/// Metadata for a single Bible book.
///
/// - `id` is a stable identifier used for `Picker` selections and persistence.
/// - `chapterCount` is the canonical upper bound used for clamping navigation.
struct BibleBook: Identifiable, Hashable {
    let id: Int
    let name: String
    let chapterCount: Int
}

/// Canonical list of Bible books with chapter counts.
///
/// This is intentionally hard-coded:
/// - It keeps the app functional offline (book navigation doesn't depend on network availability).
/// - It provides consistent ordering/IDs across app launches and versions.
enum BibleBookCatalog {
    static let all: [BibleBook] = [
        .init(id: 1, name: "Genesis", chapterCount: 50),
        .init(id: 2, name: "Exodus", chapterCount: 40),
        .init(id: 3, name: "Leviticus", chapterCount: 27),
        .init(id: 4, name: "Numbers", chapterCount: 36),
        .init(id: 5, name: "Deuteronomy", chapterCount: 34),
        .init(id: 6, name: "Joshua", chapterCount: 24),
        .init(id: 7, name: "Judges", chapterCount: 21),
        .init(id: 8, name: "Ruth", chapterCount: 4),
        .init(id: 9, name: "1 Samuel", chapterCount: 31),
        .init(id: 10, name: "2 Samuel", chapterCount: 24),
        .init(id: 11, name: "1 Kings", chapterCount: 22),
        .init(id: 12, name: "2 Kings", chapterCount: 25),
        .init(id: 13, name: "1 Chronicles", chapterCount: 29),
        .init(id: 14, name: "2 Chronicles", chapterCount: 36),
        .init(id: 15, name: "Ezra", chapterCount: 10),
        .init(id: 16, name: "Nehemiah", chapterCount: 13),
        .init(id: 17, name: "Esther", chapterCount: 10),
        .init(id: 18, name: "Job", chapterCount: 42),
        .init(id: 19, name: "Psalms", chapterCount: 150),
        .init(id: 20, name: "Proverbs", chapterCount: 31),
        .init(id: 21, name: "Ecclesiastes", chapterCount: 12),
        .init(id: 22, name: "Song of Solomon", chapterCount: 8),
        .init(id: 23, name: "Isaiah", chapterCount: 66),
        .init(id: 24, name: "Jeremiah", chapterCount: 52),
        .init(id: 25, name: "Lamentations", chapterCount: 5),
        .init(id: 26, name: "Ezekiel", chapterCount: 48),
        .init(id: 27, name: "Daniel", chapterCount: 12),
        .init(id: 28, name: "Hosea", chapterCount: 14),
        .init(id: 29, name: "Joel", chapterCount: 3),
        .init(id: 30, name: "Amos", chapterCount: 9),
        .init(id: 31, name: "Obadiah", chapterCount: 1),
        .init(id: 32, name: "Jonah", chapterCount: 4),
        .init(id: 33, name: "Micah", chapterCount: 7),
        .init(id: 34, name: "Nahum", chapterCount: 3),
        .init(id: 35, name: "Habakkuk", chapterCount: 3),
        .init(id: 36, name: "Zephaniah", chapterCount: 3),
        .init(id: 37, name: "Haggai", chapterCount: 2),
        .init(id: 38, name: "Zechariah", chapterCount: 14),
        .init(id: 39, name: "Malachi", chapterCount: 4),
        .init(id: 40, name: "Matthew", chapterCount: 28),
        .init(id: 41, name: "Mark", chapterCount: 16),
        .init(id: 42, name: "Luke", chapterCount: 24),
        .init(id: 43, name: "John", chapterCount: 21),
        .init(id: 44, name: "Acts", chapterCount: 28),
        .init(id: 45, name: "Romans", chapterCount: 16),
        .init(id: 46, name: "1 Corinthians", chapterCount: 16),
        .init(id: 47, name: "2 Corinthians", chapterCount: 13),
        .init(id: 48, name: "Galatians", chapterCount: 6),
        .init(id: 49, name: "Ephesians", chapterCount: 6),
        .init(id: 50, name: "Philippians", chapterCount: 4),
        .init(id: 51, name: "Colossians", chapterCount: 4),
        .init(id: 52, name: "1 Thessalonians", chapterCount: 5),
        .init(id: 53, name: "2 Thessalonians", chapterCount: 3),
        .init(id: 54, name: "1 Timothy", chapterCount: 6),
        .init(id: 55, name: "2 Timothy", chapterCount: 4),
        .init(id: 56, name: "Titus", chapterCount: 3),
        .init(id: 57, name: "Philemon", chapterCount: 1),
        .init(id: 58, name: "Hebrews", chapterCount: 13),
        .init(id: 59, name: "James", chapterCount: 5),
        .init(id: 60, name: "1 Peter", chapterCount: 5),
        .init(id: 61, name: "2 Peter", chapterCount: 3),
        .init(id: 62, name: "1 John", chapterCount: 5),
        .init(id: 63, name: "2 John", chapterCount: 1),
        .init(id: 64, name: "3 John", chapterCount: 1),
        .init(id: 65, name: "Jude", chapterCount: 1),
        .init(id: 66, name: "Revelation", chapterCount: 22)
    ]
}

/// The most common JSON shape for chapter payloads in the upstream dataset.
///
/// Example:
/// `{ "verses": [ { ... }, { ... } ] }`
struct ChapterResponse: Decodable {
    let verses: [Verse]
}

/// A single Bible verse.
///
/// The upstream JSON dataset is not perfectly consistent across versions/files:
/// - Field names can vary (e.g. `book` vs `book_name`, `chapter` vs `chapter_nr`)
/// - Numeric fields can be encoded as either numbers or strings
///
/// The custom `Decodable` implementation makes the app resilient to those variations so
/// a single outlier JSON file doesn’t break reading/search flows.
struct Verse: Decodable, Identifiable {
    /// A stable identifier for SwiftUI lists.
    ///
    /// We prefer a deterministic id over a random UUID so the same verse re-renders predictably
    /// across cache refreshes. If the payload omits the book name, we fall back to `"unknown"`.
    var id: String { "\(book ?? "unknown")-\(chapter)-\(verse)" }

    /// Book name as provided by the payload (may be missing in some files).
    let book: String?
    /// 1-based chapter number (defaults to 0 if the payload is malformed).
    let chapter: Int
    /// 1-based verse number (defaults to 0 if the payload is malformed).
    let verse: Int
    /// Verse text (defaults to empty string if the payload is malformed).
    let text: String

    enum CodingKeys: String, CodingKey {
        case book
        case bookName = "book_name"
        case chapter
        case chapterNr = "chapter_nr"
        case verse
        case verseNr = "verse_nr"
        case text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Support both `book` and `book_name` depending on the file/version.
        book =
            (try? container.decodeIfPresent(String.self, forKey: .book)) ??
            (try? container.decodeIfPresent(String.self, forKey: .bookName))

        // Some sources encode numbers as strings. We accept both to reduce brittleness.
        func decodeInt(forKey key: CodingKeys) -> Int? {
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return value
            }
            if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
               let value = Int(stringValue) {
                return value
            }
            return nil
        }

        // Prefer the more "standard" keys, but fall back to `_nr` keys when present.
        chapter = decodeInt(forKey: .chapter) ?? decodeInt(forKey: .chapterNr) ?? 0
        verse = decodeInt(forKey: .verse) ?? decodeInt(forKey: .verseNr) ?? 0

        // Missing text is treated as empty to avoid failing the entire decode for one bad entry.
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
    }
}

extension Verse {
    /// Convenience initializer used by tests and caching layers.
    init(book: String?, chapter: Int, verse: Int, text: String) {
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.text = text
    }

    /// Fills book/chapter/verse from the request when the payload omits them.
    ///
    /// Per-verse JSON files often include only `verse` and `text` because chapter/book are implied by the URL.
    func resolvingReferences(book: String, chapter: Int, verse: Int) -> Verse {
        let trimmedBook = book.trimmingCharacters(in: .whitespacesAndNewlines)
        return Verse(
            book: self.book ?? (trimmedBook.isEmpty ? nil : trimmedBook),
            chapter: self.chapter > 0 ? self.chapter : chapter,
            verse: self.verse > 0 ? self.verse : verse,
            text: text
        )
    }
}
