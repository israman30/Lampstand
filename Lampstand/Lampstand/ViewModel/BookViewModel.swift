//
//  BookViewModel.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import SwiftUI
import Combine

protocol BookViewModelProtocol {
    func fetchVerses() async
}

extension BookViewModel: BookViewModelProtocol { }

@MainActor
final class BookViewModel: ObservableObject {
    @Published var verses: [Verse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var version: String = "en-asv"
    @Published private(set) var navigationTitle: String = "Genesis 1"
    
    private let networkManager: NetworkManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private var activeSearchTask: Task<Void, Never>?

    private let defaultBook = "genesis"
    private let defaultChapter = 1
    
    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager

        $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .dropFirst()
            .sink { [weak self] text in
                guard let self else { return }
                self.activeSearchTask?.cancel()
                self.activeSearchTask = Task { [weak self] in
                    guard let self else { return }
                    await self.fetchForQuery(text)
                }
            }
            .store(in: &cancellables)

        $version
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.activeSearchTask?.cancel()
                self.activeSearchTask = Task { [weak self] in
                    guard let self else { return }
                    await self.fetchForQuery(self.searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchVerses() async {
        await fetch(book: defaultBook, chapter: defaultChapter, titleOverride: "Genesis 1")
    }

    private func fetchForQuery(_ query: String) async {
        if query.isEmpty {
            await fetch(book: defaultBook, chapter: defaultChapter, titleOverride: "Genesis 1")
            return
        }

        guard let parsed = Self.parseBookAndChapter(from: query) else {
            // Don’t spam errors while the user is typing partial input.
            return
        }

        if let verse = parsed.verse {
            let title = "\(Self.prettyBookName(parsed.book)) \(parsed.chapter):\(verse)"
            await fetch(book: parsed.book, chapter: parsed.chapter, verse: verse, titleOverride: title)
        } else {
            let title = "\(Self.prettyBookName(parsed.book)) \(parsed.chapter)"
            await fetch(book: parsed.book, chapter: parsed.chapter, titleOverride: title)
        }
    }

    private func fetch(book: String, chapter: Int, titleOverride: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let results = try await networkManager.fetchChapter(book: book, chapter: chapter, version: version)
            verses = results
            navigationTitle = results.first?.book.map { "\($0) \(chapter)" } ?? titleOverride
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            verses = []
            navigationTitle = titleOverride
        }
        isLoading = false
    }

    private func fetch(book: String, chapter: Int, verse: Int, titleOverride: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await networkManager.fetchVerse(book: book, chapter: chapter, verse: verse, version: version)
            verses = [result]
            if let bookName = result.book {
                navigationTitle = "\(bookName) \(chapter):\(verse)"
            } else {
                navigationTitle = titleOverride
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            verses = []
            navigationTitle = titleOverride
        }
        isLoading = false
    }

    private static func parseBookAndChapter(from query: String) -> (book: String, chapter: Int, verse: Int?)? {
        let cleaned = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: " ")

        guard !cleaned.isEmpty else { return nil }

        let parts = cleaned.split(whereSeparator: \.isWhitespace).map(String.init)
        guard parts.count >= 2 else { return nil }

        // Accept "John 3", "1 John 3", and "John 3:16".
        let last = parts.last ?? ""
        let tokens = last.split(separator: ":", omittingEmptySubsequences: false).map(String.init)

        guard let chapterToken = tokens.first,
              let chapter = Int(chapterToken),
              chapter > 0 else { return nil }

        var verse: Int?
        if tokens.count >= 2 {
            let verseToken = tokens[1]
            guard !verseToken.isEmpty, let v = Int(verseToken), v > 0 else { return nil }
            verse = v
        }

        let book = parts.dropLast().joined(separator: " ")
        guard !book.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        return (book: book, chapter: chapter, verse: verse)
    }

    private static func prettyBookName(_ book: String) -> String {
        book
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .map { token in
                if token.count <= 2, token.allSatisfy(\.isNumber) { return String(token) }
                return token.prefix(1).uppercased() + token.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}
