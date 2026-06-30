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
            // We successfully reached the endpoint, but the JSON shape isn't one we know how to decode.
            return "Unexpected JSON payload."
        case .invalidURL:
            return "Invalid request URL."
        }
    }
}

protocol NetworkManagerProtocol {
    /// Fetches a chapter's verses from the static JSON endpoint.
    /// - Note: This API is backed by a CDN-hosted GitHub repo, so payload shapes can vary by file/version.
    func fetchChapter(book: String, chapter: Int, version: String) async throws -> [Verse]

    /// Convenience helper used by the reader UI to include prev/next chapter hints.
    func fetchChapterPage(book: String, chapter: Int, totalChapters: Int, version: String) async throws -> ChapterPage

    /// Fetches a single verse.
    /// - Note: Some verse endpoints return either a raw `Verse` object or a small wrapper object.
    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async throws -> Verse
}

extension NetworkManager: NetworkManagerProtocol { }

final class NetworkManager {
    private let baseURL: URL
    private static let endpointURL = URL(string: "https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles")!

    /// Base path for the Bible API JSON files.
    /// - Important: These are static JSON files served via jsDelivr, not a traditional REST service.
    init(baseURL: URL = endpointURL) {
        self.baseURL = baseURL
    }

    func fetchChapter(book: String, chapter: Int, version: String) async throws -> [Verse] {
        let versionSlug = Self.slugify(version)
        let bookSlug = Self.slugify(book)
        // Guard early so we never generate malformed URLs like ".../books//chapters/0.json".
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

        // We use `URLSession.shared` (no auth/cookies) since the content is public, cache-friendly JSON.
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpStatus(http.statusCode)
        }

        let decoder = JSONDecoder()

        // The upstream repo isn't fully consistent across files:
        // - Sometimes the response is a plain `Verse`
        // - Sometimes it's wrapped (e.g., { "verse": { ... } })
        if let verse = try? decoder.decode(Verse.self, from: data) {
            return verse
        }

        struct VerseWrapper: Decodable {
            let verse: Verse
        }
        
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

        // Fallback shapes: the dataset may evolve or differ by version/file, so we support a couple of
        // common alternatives to avoid breaking reading/search when a single JSON file differs.
        if let verses = try? decoder.decode([Verse].self, from: data) {
            return verses
        }

        struct DataWrapper: Decodable {
            let data: [Verse]
        }
        
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

        // The upstream file paths are kebab-case-ish. This keeps URLs predictable for inputs like:
        // - "1 Samuel" -> "1-samuel"
        // - "Song of Solomon" -> "song-of-solomon"
        // It’s intentionally conservative: anything non-alphanumeric becomes a single "-".
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
