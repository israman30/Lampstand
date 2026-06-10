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
    @Published var bookText: String = ""
    @Published var chapterText: String = ""
    @Published var verseText: String = ""
    @Published var version: String = "en-asv"
    @Published private(set) var navigationTitle: String = "Lampstand"
    
    private let networkManager: NetworkManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private var activeFetchTask: Task<Void, Never>?
    
    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager

        $bookText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.activeFetchTask?.cancel()
                self.chapterText = ""
                self.verseText = ""
                self.verses = []
                self.errorMessage = nil
                self.isLoading = false
                self.navigationTitle = "Lampstand"
            }
            .store(in: &cancellables)

        $chapterText
            .map(Self.sanitizeNumberText(_:))
            .removeDuplicates()
            .sink { [weak self] sanitized in
                guard let self else { return }
                if self.chapterText != sanitized {
                    self.chapterText = sanitized
                    return
                }

                self.activeFetchTask?.cancel()
                self.verseText = ""
                self.verses = []
                self.errorMessage = nil
                self.isLoading = false
            }
            .store(in: &cancellables)

        $verseText
            .map(Self.sanitizeNumberText(_:))
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] sanitized in
                guard let self else { return }
                if self.verseText != sanitized {
                    self.verseText = sanitized
                    return
                }

                self.errorMessage = nil
                self.verses = []
                self.isLoading = false
                self.triggerFetchIfPossible()
            }
            .store(in: &cancellables)

        $version
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.triggerFetchIfPossible()
            }
            .store(in: &cancellables)
    }
    
    func fetchVerses() async {
        // Intentionally no-op. The main view now waits for the user to provide
        // Book + Chapter + Verse before fetching.
    }

    private func triggerFetchIfPossible() {
        activeFetchTask?.cancel()

        let book = bookText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !book.isEmpty else { return }
        guard let chapter = Int(chapterText), chapter > 0 else { return }
        guard let verse = Int(verseText), verse > 0 else { return }

        let titleOverride = "\(Self.prettyBookName(book)) \(chapter):\(verse)"
        activeFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetch(book: book, chapter: chapter, verse: verse, titleOverride: titleOverride)
        }
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

    var displayedVerse: Verse? { verses.first }

    var placeholderTitle: String {
        if bookText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter a book"
        }
        if Int(chapterText) == nil {
            return "Enter a chapter"
        }
        if Int(verseText) == nil {
            return "Enter a verse"
        }
        return "Searching…"
    }

    var placeholderMessage: String {
        if bookText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Start with a book name, like “John”."
        }
        if Int(chapterText) == nil {
            return "Now enter a chapter number, like “3”."
        }
        if Int(verseText) == nil {
            return "Now enter a verse number, like “16”."
        }
        return "If nothing appears, check spelling or try a different version."
    }

    var chapterEnabled: Bool {
        !bookText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var verseEnabled: Bool {
        chapterEnabled && (Int(chapterText) ?? 0) > 0
    }

    private static func sanitizeNumberText(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        // Prevent ridiculously long inputs.
        return String(digits.prefix(4))
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
