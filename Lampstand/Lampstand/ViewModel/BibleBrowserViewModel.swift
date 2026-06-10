//
//  BibleBrowserViewModel.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/10/26.
//

import Foundation
import Combine

@MainActor
final class BibleBrowserViewModel: ObservableObject {
    @Published var selectedBookId: Int = BibleBookCatalog.all.first?.id ?? 1

    @Published private(set) var verses: [Verse] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var selectedChapter: Int = 1
    @Published var version: String = "en-asv"

    private let networkManager: NetworkManagerProtocol
    private var activeFetchTask: Task<Void, Never>?

    init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
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

    func selectBook(id: Int) {
        selectedBookId = id
        selectedChapter = 1
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

        selectedChapter = clamp(selectedChapter, to: 1...max(1, book.chapterCount))

        let chapter = selectedChapter
        let version = version

        activeFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetch(book: book, chapter: chapter, version: version)
        }
    }

    func goToPreviousChapter() {
        guard let book = selectedBook else { return }
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

        do {
            let page = try await networkManager.fetchChapterPage(
                book: book.name,
                chapter: chapter,
                totalChapters: book.chapterCount,
                version: version
            )
            verses = page.verses
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            verses = []
        }
    }

    private func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

