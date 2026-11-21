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
    @Published private(set) var searchValidationMessage: String?

    private let networkManager: NetworkManagerProtocol
    private let verseStore: VerseStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    // We cancel in-flight work on any input change to avoid racing updates (e.g., the user types “1”, then “16”)
    // and to ensure only the latest (book, chapter, verse, version) selection can win.
    private var activeFetchTask: Task<Void, Never>?
    private var verseDebounceTask: Task<Void, Never>?
    private var isInitializing = false

    private enum BibleBooks: String, CaseIterable {
        case genesis = "Genesis"
        case exodus = "Exodus"
        case leviticus = "Leviticus"
        case numbers = "Numbers"
        case deuteronomy = "Deuteronomy"
        case joshua = "Joshua"
        case judges = "Judges"
        case ruth = "Ruth"
        case samuel1 = "1 Samuel"
        case samuel2 = "2 Samuel"
        case kings1 = "1 Kings"
        case kings2 = "2 Kings"
        case chronicles1 = "1 Chronicles"
        case chronicles2 = "2 Chronicles"
        case ezra = "Ezra"
        case nehemiah = "Nehemiah"
        case esther = "Esther"
        case job = "Job"
        case psalms = "Psalms"
        case proverbs = "Proverbs"
        case ecclesiastes = "Ecclesiastes"
        case songOfSolomon = "Song of Solomon"
        case isaiah = "Isaiah"
        case jeremiah = "Jeremiah"
        case lamentations = "Lamentations"
        case ezekiel = "Ezekiel"
        case daniel = "Daniel"
        case hosea = "Hosea"
        case joel = "Joel"
        case amos = "Amos"
        case obadiah = "Obadiah"
        case jonah = "Jonah"
        case micah = "Micah"
        case nahum = "Nahum"
        case habakkuk = "Habakkuk"
        case zephaniah = "Zephaniah"
        case haggai = "Haggai"
        case zechariah = "Zechariah"
        case malachi = "Malachi"
        case matthew = "Matthew"
        case mark = "Mark"
        case luke = "Luke"
        case john = "John"
        case acts = "Acts"
        case romans = "Romans"
        case corinthians1 = "1 Corinthians"
        case corinthians2 = "2 Corinthians"
        case galatians = "Galatians"
        case ephesians = "Ephesians"
        case philippians = "Philippians"
        case colossians = "Colossians"
        case thessalonians1 = "1 Thessalonians"
        case thessalonians2 = "2 Thessalonians"
        case timothy1 = "1 Timothy"
        case timothy2 = "2 Timothy"
        case titus = "Titus"
        case philemon = "Philemon"
        case hebrews = "Hebrews"
        case james = "James"
        case peter1 = "1 Peter"
        case peter2 = "2 Peter"
        case john1 = "1 John"
        case john2 = "2 John"
        case john3 = "3 John"
        case jude = "Jude"
        case revelation = "Revelation"

        static let collection: [String] = Self.allCases.map(\.rawValue)

        var slug: String {
            rawValue
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "'", with: "")
        }

        static func canonicalName(for input: String) -> String? {
            let normalizedInput = normalize(input)
            guard !normalizedInput.isEmpty else { return nil }

            return Self.allCases.first { book in
                normalize(book.rawValue) == normalizedInput
            }?.rawValue
        }

        private static func normalize(_ value: String) -> String {
            value
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .replacingOccurrences(of: "’", with: "'")
                .replacingOccurrences(of: "-", with: " ")
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    init(networkManager: NetworkManagerProtocol, verseStore: VerseStoreProtocol? = nil) {
        self.networkManager = networkManager
        self.verseStore = verseStore ?? CoreDataVerseStore.shared

        $bookText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .sink { [weak self] book in
                guard let self, !self.isInitializing else { return }
                self.activeFetchTask?.cancel()
                self.chapterText = ""
                self.verseText = ""
                self.verses = []
                self.errorMessage = nil
                self.isLoading = false
                self.navigationTitle = book.isEmpty ? "Lampstand" : Self.prettyBookName(book)
                self.updateSearchValidationMessage()
            }
            .store(in: &cancellables)

        $version
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, !self.isInitializing else { return }
                self.triggerFetchIfPossible()
            }
            .store(in: &cancellables)
    }
    
    var availableBooks: [String] { BibleBooks.collection }

    func fetchVerses() async {
        // Intentionally no-op. The main view now waits for the user to provide
        // Book + Chapter + Verse before fetching.
    }

    var selectedBookChapterCount: Int? {
        let canonical = Self.resolveBookName(bookText)
        return BibleBookCatalog.all.first(where: { $0.name == canonical })?.chapterCount
    }

    var selectedChapterIsValid: Bool {
        guard let chapter = Int(chapterText), chapter > 0 else { return false }
        guard let chapterCount = selectedBookChapterCount else { return true }
        return chapter <= chapterCount
    }

    private func updateSearchValidationMessage() {
        guard let chapterCount = selectedBookChapterCount else {
            searchValidationMessage = nil
            return
        }

        let book = Self.prettyBookName(bookText)
        if let chapter = Int(chapterText), chapter > 0, chapter > chapterCount {
            searchValidationMessage = "\(book) has only \(chapterCount) chapter\(chapterCount == 1 ? "" : "s"). Choose a chapter from 1 to \(chapterCount)."
            return
        }

        searchValidationMessage = nil
    }

    private func triggerFetchIfPossible() {
        activeFetchTask?.cancel()

        let rawBook = bookText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawBook.isEmpty else { return }
        guard let chapter = Int(chapterText), chapter > 0 else { return }
        guard let verse = Int(verseText), verse > 0 else { return }

        updateSearchValidationMessage()
        guard selectedChapterIsValid else {
            verses = []
            errorMessage = nil
            return
        }

        let book = Self.resolveBookName(rawBook) ?? rawBook
        let titleOverride = "\(Self.prettyBookName(book)) \(chapter):\(verse)"
        // Task cancellation is our “latest request wins” strategy, which also keeps cached vs. network updates
        // from stomping on each other when inputs change quickly.
        activeFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetch(book: book, chapter: chapter, verse: verse, titleOverride: titleOverride)
        }
    }

    private func fetch(book: String, chapter: Int, verse: Int, titleOverride: String) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        let canonicalBook = Self.resolveBookName(book) ?? book

        // Validate the verse against the chapter's actual loaded data. This also
        // handles chapter-specific verse counts that cannot be inferred from the book name.
        do {
            let chapterVerses = try await networkManager.fetchChapter(
                book: canonicalBook,
                chapter: chapter,
                version: version
            )
            guard !Task.isCancelled else { return }

            if verse > chapterVerses.count {
                searchValidationMessage = "\(Self.prettyBookName(canonicalBook)) \(chapter) has only \(chapterVerses.count) verse\(chapterVerses.count == 1 ? "" : "s"). Choose a verse from 1 to \(chapterVerses.count)."
                verses = []
                return
            }
        } catch {
            // If chapter probing fails (for example, a test/mock or unavailable network),
            // preserve the existing single-verse fetch and let that endpoint report the result.
        }

        searchValidationMessage = nil
        errorMessage = nil

        let cachedVerse = await verseStore.fetchVerse(book: canonicalBook, chapter: chapter, verse: verse, version: version)
        if let cachedVerse, !Task.isCancelled {
            let resolved = cachedVerse.resolvingReferences(book: canonicalBook, chapter: chapter, verse: verse)
            verses = [resolved]
            navigationTitle = "\(resolved.book ?? canonicalBook) \(resolved.chapter):\(resolved.verse)"
        }

        do {
            guard !Task.isCancelled else { return }
            let result = try await networkManager.fetchVerse(book: canonicalBook, chapter: chapter, verse: verse, version: version)
            guard !Task.isCancelled else { return }
            let resolved = result.resolvingReferences(book: canonicalBook, chapter: chapter, verse: verse)
            verses = [resolved]
            if let bookName = resolved.book {
                navigationTitle = "\(bookName) \(resolved.chapter):\(resolved.verse)"
            } else {
                navigationTitle = titleOverride
            }

            await verseStore.upsert(verse: resolved, bookFallback: canonicalBook, version: version)
        } catch {
            if cachedVerse == nil {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                verses = []
                navigationTitle = titleOverride
            }
        }
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

    private static func resolveBookName(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return BibleBooks.canonicalName(for: trimmed) ?? trimmed
    }

    private static func sanitizeNumberText(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        // Prevent ridiculously long inputs.
        return String(digits.prefix(4))
    }

    private static func prettyBookName(_ book: String) -> String {
        let resolved = resolveBookName(book) ?? book
        let tokens = resolved
            .split(whereSeparator: \ .isWhitespace)
            .map { token in
                if token.count <= 2, token.allSatisfy(\.isNumber) { return String(token) }
                return token.prefix(1).uppercased() + token.dropFirst().lowercased()
            }
        return tokens.joined(separator: " ")
    }

    /// Applies preselected search values as one transaction instead of triggering
    /// independent reset behavior for book, chapter, and verse publications.
    func configure(book: String, chapter: Int, verse: Int?, version: String) {
        isInitializing = true
        activeFetchTask?.cancel()

        bookText = book
        chapterText = chapter > 0 ? String(chapter) : ""
        verseText = verse.map(String.init) ?? ""
        self.version = version

        let canonicalBook = Self.prettyBookName(book)
        if !canonicalBook.isEmpty, chapter > 0, let selectedVerse = verse, selectedVerse > 0 {
            navigationTitle = "\(canonicalBook) \(chapter):\(selectedVerse)"
        } else if !canonicalBook.isEmpty, chapter > 0 {
            navigationTitle = "\(canonicalBook) \(chapter)"
        } else {
            navigationTitle = canonicalBook.isEmpty ? "Lampstand" : canonicalBook
        }

        isInitializing = false
        updateSearchValidationMessage()

        if verse != nil {
            triggerFetchIfPossible()
        }
    }

    func updateChapter(_ input: String) {
        let sanitized = Self.sanitizeNumberText(input)
        guard chapterText != sanitized else { return }

        activeFetchTask?.cancel()
        chapterText = sanitized
        verseText = ""
        verses = []
        errorMessage = nil
        isLoading = false

        let book = Self.prettyBookName(bookText)
        if let chapter = Int(sanitized), chapter > 0 {
            navigationTitle = "\(book) \(chapter)"
        } else {
            navigationTitle = book.isEmpty ? "Lampstand" : book
        }

        updateSearchValidationMessage()
    }

    func updateVerse(_ input: String) {
        let sanitized = Self.sanitizeNumberText(input)
        guard verseText != sanitized else { return }

        verseDebounceTask?.cancel()
        verseText = sanitized
        verses = []
        errorMessage = nil
        isLoading = false

        let book = Self.prettyBookName(bookText)
        if let chapter = Int(chapterText), chapter > 0,
           let verse = Int(sanitized), verse > 0 {
            navigationTitle = "\(book) \(chapter):\(verse)"
        } else {
            navigationTitle = book.isEmpty ? "Lampstand" : "\(book) \(chapterText)"
        }

        guard !sanitized.isEmpty else { return }

        verseDebounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.triggerFetchIfPossible()
            }
        }
    }
}
