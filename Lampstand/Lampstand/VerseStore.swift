//
//  VerseStore.swift
//  Lampstand
//
//  Created by Cursor on 6/10/26.
//

import CoreData

protocol VerseStoreProtocol {
    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async -> Verse?
    func fetchChapter(book: String, chapter: Int, version: String) async -> [Verse]
    func upsert(verse: Verse, bookFallback: String, version: String) async
    func upsert(verses: [Verse], bookFallback: String, chapter: Int, version: String) async
}

final class CoreDataVerseStore: VerseStoreProtocol {
    static let shared = CoreDataVerseStore(persistence: .shared)

    private let readContext: NSManagedObjectContext
    private let writeContext: NSManagedObjectContext

    init(persistence: PersistenceController) {
        self.readContext = persistence.container.viewContext
        self.writeContext = persistence.container.newBackgroundContext()
        self.writeContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async -> Verse? {
        let book = book.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = version.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = Self.makeKey(book: book, chapter: chapter, verse: verse, version: version)

        return await readContext.perform {
            let request = CachedVerse.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "key == %@", key)

            guard let cached = (try? self.readContext.fetch(request))?.first else {
                return nil
            }

            return Verse(
                book: cached.book ?? book,
                chapter: Int(cached.chapter),
                verse: Int(cached.verse),
                text: cached.text
            )
        }
    }

    func fetchChapter(book: String, chapter: Int, version: String) async -> [Verse] {
        let book = book.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = version.trimmingCharacters(in: .whitespacesAndNewlines)

        return await readContext.perform {
            let request = CachedVerse.fetchRequest()
            request.predicate = NSPredicate(format: "book == %@ AND chapter == %d AND version == %@", book, chapter, version)
            request.sortDescriptors = [
                NSSortDescriptor(key: "verse", ascending: true),
                NSSortDescriptor(key: "fetchedAt", ascending: false)
            ]

            let cached = (try? self.readContext.fetch(request)) ?? []
            return cached.map {
                Verse(
                    book: $0.book ?? book,
                    chapter: Int($0.chapter),
                    verse: Int($0.verse),
                    text: $0.text
                )
            }
        }
    }

    func upsert(verse: Verse, bookFallback: String, version: String) async {
        let book = (verse.book ?? bookFallback).trimmingCharacters(in: .whitespacesAndNewlines)
        await upsert(verses: [verse], bookFallback: book, chapter: verse.chapter, version: version)
    }

    func upsert(verses: [Verse], bookFallback: String, chapter: Int, version: String) async {
        let book = bookFallback.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = version.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        await writeContext.perform {
            let existingRequest = CachedVerse.fetchRequest()
            existingRequest.predicate = NSPredicate(format: "book == %@ AND chapter == %d AND version == %@", book, chapter, version)
            let existing = (try? self.writeContext.fetch(existingRequest)) ?? []
            var byVerse: [Int: CachedVerse] = Dictionary(uniqueKeysWithValues: existing.map { (Int($0.verse), $0) })

            for verse in verses {
                let verseNumber = verse.verse
                let key = Self.makeKey(book: book, chapter: chapter, verse: verseNumber, version: version)

                let object = byVerse[verseNumber] ?? CachedVerse(context: self.writeContext)
                object.key = key
                object.book = verse.book ?? book
                object.chapter = Int16(chapter)
                object.verse = Int16(verseNumber)
                object.version = version
                object.text = verse.text
                object.fetchedAt = now

                byVerse[verseNumber] = object
            }

            guard self.writeContext.hasChanges else { return }
            try? self.writeContext.save()
        }
    }

    private static func makeKey(book: String, chapter: Int, verse: Int, version: String) -> String {
        "\(version.lowercased())|\(book.lowercased())|\(chapter)|\(verse)"
    }
}

