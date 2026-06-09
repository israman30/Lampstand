//
//  Model.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import Foundation

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
