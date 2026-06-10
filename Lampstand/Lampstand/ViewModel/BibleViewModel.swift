//
//  BibleViewModel.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import Foundation
import Combine

@MainActor
final class BibleViewModel: ObservableObject {
    @Published var verses: [Verse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedChapter: Int
    @Published var version: String

    let book: String
    let totalChapters: Int

    private let networkManager: NetworkManagerProtocol
    private var activeFetchTask: Task<Void, Never>?

    init(
        book: String = "Genesis",
        totalChapters: Int = 50,
        initialChapter: Int = 1,
        version: String = "en-asv",
        networkManager: NetworkManagerProtocol
    ) {
        self.book = book
        self.totalChapters = max(1, totalChapters)
        self.selectedChapter = min(max(1, initialChapter), self.totalChapters)
        self.version = version
        self.networkManager = networkManager
    }

    func fetchSelectedChapter() {
        activeFetchTask?.cancel()
        errorMessage = nil

        let chapter = selectedChapter
        let book = book
        let totalChapters = totalChapters
        let version = version

        activeFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetch(book: book, chapter: chapter, totalChapters: totalChapters, version: version)
        }
    }

    private func fetch(book: String, chapter: Int, totalChapters: Int, version: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let page = try await networkManager.fetchChapterPage(
                book: book,
                chapter: chapter,
                totalChapters: totalChapters,
                version: version
            )
            verses = page.verses
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            verses = []
        }
    }
}

