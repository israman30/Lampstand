//
//  Model.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import Foundation

struct ChapterPage {
    let book: String
    let chapter: Int
    let verses: [Verse]
    let previousChapter: Int?
    let nextChapter: Int?
}

struct BibleBook: Identifiable, Hashable {
    let id: Int
    let name: String
    let chapterCount: Int
}

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

struct ChapterResponse: Decodable {
    let verses: [Verse]
}

struct Verse: Decodable, Identifiable {
    var id: String { "\(book ?? "unknown")-\(chapter)-\(verse)" }

    let book: String?
    let chapter: Int
    let verse: Int
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

        book =
            (try? container.decodeIfPresent(String.self, forKey: .book)) ??
            (try? container.decodeIfPresent(String.self, forKey: .bookName))

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

        chapter = decodeInt(forKey: .chapter) ?? decodeInt(forKey: .chapterNr) ?? 0
        verse = decodeInt(forKey: .verse) ?? decodeInt(forKey: .verseNr) ?? 0

        text = (try? container.decode(String.self, forKey: .text)) ?? ""
    }
}
