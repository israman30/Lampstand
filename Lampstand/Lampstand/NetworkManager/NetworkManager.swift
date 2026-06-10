//
//  NetworkManager.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case unexpectedPayload
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .httpStatus(let code):
            return "Request failed with status code \(code)."
        case .unexpectedPayload:
            return "Unexpected JSON payload."
        case .invalidURL:
            return "Invalid request URL."
        }
    }
}

protocol NetworkManagerProtocol {
    func fetchChapter(book: String, chapter: Int, version: String) async throws -> [Verse]
    func fetchChapterPage(book: String, chapter: Int, totalChapters: Int, version: String) async throws -> ChapterPage
    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async throws -> Verse
}

extension NetworkManager: NetworkManagerProtocol { }

final class NetworkManager {
    private let baseURL: URL

    init(baseURL: URL = URL(string: "https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles")!) {
        self.baseURL = baseURL
    }

    func fetchChapter(book: String, chapter: Int, version: String) async throws -> [Verse] {
        let versionSlug = Self.slugify(version)
        let bookSlug = Self.slugify(book)
        guard !versionSlug.isEmpty, !bookSlug.isEmpty, chapter > 0 else { throw NetworkError.invalidURL }

        let url = baseURL
            .appendingPathComponent(versionSlug)
            .appendingPathComponent("books")
            .appendingPathComponent(bookSlug)
            .appendingPathComponent("chapters")
            .appendingPathComponent("\(chapter).json")

        return try await decodeVerses(from: url)
    }

    func fetchChapterPage(book: String, chapter: Int, totalChapters: Int, version: String) async throws -> ChapterPage {
        guard totalChapters > 0, (1...totalChapters).contains(chapter) else { throw NetworkError.invalidURL }

        let verses = try await fetchChapter(book: book, chapter: chapter, version: version)
        let previous = (chapter > 1) ? (chapter - 1) : nil
        let next = (chapter < totalChapters) ? (chapter + 1) : nil

        return ChapterPage(book: book, chapter: chapter, verses: verses, previousChapter: previous, nextChapter: next)
    }

    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async throws -> Verse {
        let versionSlug = Self.slugify(version)
        let bookSlug = Self.slugify(book)
        guard !versionSlug.isEmpty, !bookSlug.isEmpty, chapter > 0, verse > 0 else { throw NetworkError.invalidURL }

        // Example:
        // https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1/verses/1.json
        let url = baseURL
            .appendingPathComponent(versionSlug)
            .appendingPathComponent("books")
            .appendingPathComponent(bookSlug)
            .appendingPathComponent("chapters")
            .appendingPathComponent("\(chapter)")
            .appendingPathComponent("verses")
            .appendingPathComponent("\(verse).json")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpStatus(http.statusCode)
        }

        let decoder = JSONDecoder()

        if let verse = try? decoder.decode(Verse.self, from: data) {
            return verse
        }

        struct VerseWrapper: Decodable { let verse: Verse }
        if let wrapper = try? decoder.decode(VerseWrapper.self, from: data) {
            return wrapper.verse
        }

        throw NetworkError.unexpectedPayload
    }

    private func decodeVerses(from url: URL) async throws -> [Verse] {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpStatus(http.statusCode)
        }

        let decoder = JSONDecoder()

        // Most common shape for chapters:
        // { ..., "verses": [ { ... }, ... ] }
        if let chapterResponse = try? decoder.decode(ChapterResponse.self, from: data) {
            return chapterResponse.verses
        }

        // Fallback shapes (some endpoints return an array, or wrap under a "data" key, etc.)
        if let verses = try? decoder.decode([Verse].self, from: data) {
            return verses
        }

        struct DataWrapper: Decodable { let data: [Verse] }
        if let wrapper = try? decoder.decode(DataWrapper.self, from: data) {
            return wrapper.data
        }

        throw NetworkError.unexpectedPayload
    }

    private static func slugify(_ input: String) -> String {
        let lower = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !lower.isEmpty else { return "" }

        // Keep alphanumerics, turn everything else into single dashes.
        let allowed = CharacterSet.alphanumerics
        var scalars: [UnicodeScalar] = []
        scalars.reserveCapacity(lower.unicodeScalars.count)

        var lastWasDash = false
        for scalar in lower.unicodeScalars {
            if allowed.contains(scalar) {
                scalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash {
                scalars.append(UnicodeScalar(45)) // "-"
                lastWasDash = true
            }
        }

        let slug = String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return slug
    }
}
