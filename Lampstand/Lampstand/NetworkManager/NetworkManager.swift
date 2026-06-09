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

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .httpStatus(let code):
            return "Request failed with status code \(code)."
        case .unexpectedPayload:
            return "Unexpected JSON payload."
        }
    }
}

protocol NetworkManagerProtocol {
    func fetchVerses() async throws -> [Verse]
}

extension NetworkManager: NetworkManagerProtocol { }

final class NetworkManager {
    private let url: URL

    init(url: URL = URL(string: "https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1.json")!) {
        self.url = url
    }

    func fetchVerses() async throws -> [Verse] {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpStatus(http.statusCode)
        }

        let decoder = JSONDecoder()

        // Most common shape for this API:
        // { ..., "verses": [ { "book": "...", "chapter": 1, "verse": 1, "text": "..." }, ... ] }
        if let chapterResponse = try? decoder.decode(ChapterResponse.self, from: data) {
            return chapterResponse.verses
        }

        // Fallback shapes (some endpoints return an array, or wrap under a "data" key, etc.)
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
}
