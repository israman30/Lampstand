//
//  ContentView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
// https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1.json

import SwiftUI
import Combine

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

        struct DataWrapper: Decodable { let data: [Verse] }
        if let wrapper = try? decoder.decode(DataWrapper.self, from: data) {
            return wrapper.data
        }

        throw NetworkError.unexpectedPayload
    }
}

@MainActor
final class BookViewModel: ObservableObject {
    @Published var verses: [Verse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func fetchVerses() async {
        isLoading = true
        errorMessage = nil
        do {
            verses = try await networkManager.fetchVerses()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            verses = []
        }
        isLoading = false
    }
}

struct ContentView: View {
    @StateObject private var viewModel: BookViewModel

    init() {
        self._viewModel = StateObject(wrappedValue: BookViewModel(networkManager: NetworkManager()))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading…")
                } else if let message = viewModel.errorMessage {
                    ContentUnavailableView("Couldn’t load", systemImage: "exclamationmark.triangle", description: Text(message))
                } else {
                    List(viewModel.verses) { verse in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Verse \(verse.verse)")
                                .font(.headline)
                            Text(verse.text)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Genesis 1")
        }
        .task {
            await viewModel.fetchVerses()
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
