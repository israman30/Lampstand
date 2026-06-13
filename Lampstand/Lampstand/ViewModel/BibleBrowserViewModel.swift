//
//  BibleBrowserViewModel.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/10/26.
//

import Foundation
import Combine

protocol BibleBrowserViewProtocol {
    func userSelectedBook(id: Int)
    func userSelectedVersion(_ newVersion: String)
}

extension BibleBrowserViewModel: BibleBrowserViewProtocol { }

@MainActor
final class BibleBrowserViewModel: ObservableObject {
    // Public inputs: these are driven by UI controls (pickers/buttons) and represent the user's intent.
    @Published var selectedBookId: Int = BibleBookCatalog.all.first?.id ?? 1

    // Rendered outputs: the view reads these to present content/loading/error states.
    @Published private(set) var verses: [Verse] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var selectedChapter: Int = 1
    @Published var version: String = "en-asv"

    private let networkManager: NetworkManagerProtocol
    private let verseStore: VerseStoreProtocol
    // Cancelling in-flight work ensures "latest navigation wins" when the user taps quickly or changes inputs.
    private var activeFetchTask: Task<Void, Never>?

    init(networkManager: NetworkManagerProtocol, verseStore: VerseStoreProtocol? = nil) {
        self.networkManager = networkManager
        self.verseStore = verseStore ?? CoreDataVerseStore.shared
    }

    var selectedBook: BibleBook? {
        BibleBookCatalog.all.first(where: { $0.id == selectedBookId })
    }

    var availableBooks: [BibleBook] {
        BibleBookCatalog.all
    }

    var chapterRange: ClosedRange<Int> {
        let count = selectedBook?.chapterCount ?? 1
        return 1...max(1, count)
    }

    var navigationTitle: String {
        guard let book = selectedBook else { return "Lampstand" }
        return "\(book.name) \(selectedChapter)"
    }

    /// User-driven selection from the book picker.
    func userSelectedBook(id: Int) {
        guard selectedBookId != id else { return }
        selectedBookId = id
        selectedChapter = 1
        verses = []
        errorMessage = nil
        fetchSelectedChapter()
    }

    /// User-driven selection from the version picker.
    func userSelectedVersion(_ newVersion: String) {
        guard version != newVersion else { return }
        version = newVersion
        fetchSelectedChapter()
    }

    /// Programmatic navigation (e.g. from `SearchBookView`) without forcing chapter 1.
    func navigateTo(bookName: String, chapter: Int, version: String) {
        if let book = BibleBookCatalog.all.first(where: { $0.name.caseInsensitiveCompare(bookName) == .orderedSame }) {
            selectedBookId = book.id
        }

        selectedChapter = max(1, chapter)
        self.version = version
        verses = []
        errorMessage = nil
        fetchSelectedChapter()
    }

    func fetchSelectedChapter() {
        activeFetchTask?.cancel()
        errorMessage = nil

        guard let book = selectedBook else {
            verses = []
            return
        }

        // Defensive: keep chapter within the selected book's bounds even if inputs were set programmatically.
        selectedChapter = clamp(selectedChapter, to: 1...max(1, book.chapterCount))

        let chapter = selectedChapter
        let version = version

        activeFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetch(book: book, chapter: chapter, version: version)
        }
    }

    func goToPreviousChapter() {
        guard selectedBook != nil else { return }
        guard selectedChapter > 1 else { return }
        selectedChapter = max(1, selectedChapter - 1)
        fetchSelectedChapter()
    }

    func goToNextChapter() {
        guard let book = selectedBook else { return }
        guard selectedChapter < book.chapterCount else { return }
        selectedChapter = min(book.chapterCount, selectedChapter + 1)
        fetchSelectedChapter()
    }

    private func fetch(book: BibleBook, chapter: Int, version: String) async {
        isLoading = true
        defer { isLoading = false }

        // Cache-first: show any previously saved verses immediately to keep navigation feeling instant,
        // then refresh from the network in the background.
        let cached = await verseStore.fetchChapter(book: book.name, chapter: chapter, version: version)
        if !cached.isEmpty, !Task.isCancelled {
            verses = cached
        }

        do {
            guard !Task.isCancelled else { return }
            let page = try await networkManager.fetchChapterPage(
                book: book.name,
                chapter: chapter,
                totalChapters: book.chapterCount,
                version: version
            )
            guard !Task.isCancelled else { return }
            verses = page.verses
            await verseStore.upsert(verses: page.verses, bookFallback: book.name, chapter: chapter, version: version)
        } catch {
            // Only show an error if we have nothing to render; if cache exists, we keep it and fail silently.
            if cached.isEmpty {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                verses = []
            }
        }
    }

    private func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

