import XCTest
import Combine
@testable import Lampstand

@MainActor
final class BibleBrowserViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    
    var network: NetworkManagerMock!
    var store: VerseStoreMock!
    var sut: BibleBrowserViewModel!
    var gate: AsyncGate!
    
    override func setUp() async throws {
        network = NetworkManagerMock(fetchChapterPage: { _, _, totalChapters, _ in
            ChapterPage(book: "Exodus", chapter: 1, verses: [], previousChapter: nil, nextChapter: min(2, totalChapters))
        })
        
        store = VerseStoreMock(fetchChapter: { _, _, _ in [] })
        sut = BibleBrowserViewModel(networkManager: network, verseStore: store)
        gate = AsyncGate()
    }

    override func tearDown() {
        cancellables.removeAll()
        network = nil
        store = nil
        sut = nil
        gate = nil
        super.tearDown()
    }

    
    func test_userSelectedBook_resetsChapter_clearsState_andStartsFetch() async throws {

        // Pre-populate state (to ensure it gets cleared/reset).
        sut.selectedChapter = 5
        sut.userSelectedVersion("en-asv")

        sut.userSelectedBook(id: 2) // Exodus

        let selectedBookId = sut.selectedBookId
        let selectedChapter = sut.selectedChapter
        let versesCount = sut.verses.count
        let errorMessage = sut.errorMessage

        XCTAssertEqual(selectedBookId, 2)
        XCTAssertEqual(selectedChapter, 1)
        XCTAssertEqual(versesCount, 0)
        XCTAssertNil(errorMessage)
    }

    func test_fetchSelectedChapter_cacheHit_setsCachedThenRefreshesFromNetwork_andUpserts() async throws {
        let cached = [
            Verse(book: "Genesis", chapter: 1, verse: 1, text: "cached-1"),
            Verse(book: "Genesis", chapter: 1, verse: 2, text: "cached-2")
        ]
        let fresh = [
            Verse(book: "Genesis", chapter: 1, verse: 1, text: "fresh-1")
        ]

        let network = NetworkManagerMock(fetchChapterPage: { book, chapter, totalChapters, version in
            _ = (book, chapter, totalChapters, version)
            await self.gate.wait()
            return ChapterPage(
                book: book,
                chapter: chapter,
                verses: fresh,
                previousChapter: (chapter > 1) ? (chapter - 1) : nil,
                nextChapter: (chapter < totalChapters) ? (chapter + 1) : nil
            )
        })

        let store = VerseStoreMock(
            fetchChapter: { _, _, _ in cached }
        )

        let sut = BibleBrowserViewModel(networkManager: network, verseStore: store)
        sut.selectedBookId = 1 // Genesis
        sut.selectedChapter = 1
        sut.version = "en-asv"

        sut.fetchSelectedChapter()

        let cachedSnapshot = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == Self.snapshot(cached)
        }
        XCTAssertEqual(Self.snapshot(cachedSnapshot), Self.snapshot(cached))

        await gate.open()

        let freshSnapshot = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == Self.snapshot(fresh)
        }
        XCTAssertEqual(Self.snapshot(freshSnapshot), Self.snapshot(fresh))

        let upserted = await store.upsertedVersesSnapshot()
        XCTAssertEqual(Self.snapshot(upserted), Self.snapshot(fresh))
    }

    func test_fetchSelectedChapter_cacheEmpty_networkFailure_setsErrorAndClearsVerses() async throws {
        struct TestError: LocalizedError { var errorDescription: String? { "Network down" } }

        let network = NetworkManagerMock(fetchChapterPage: { _, _, _, _ in
            throw TestError()
        })

        let sut = BibleBrowserViewModel(networkManager: network, verseStore: store)
        sut.selectedBookId = 1 // Genesis
        sut.selectedChapter = 1
        sut.version = "en-asv"

        sut.fetchSelectedChapter()

        let message = try await waitForErrorMessage(from: sut) { $0 == "Network down" }
        XCTAssertEqual(message, "Network down")

        let versesCount = sut.verses.count
        XCTAssertEqual(versesCount, 0)
    }

    func test_fetchSelectedChapter_cacheHit_networkFailure_keepsCached_andDoesNotShowError() async throws {
        struct TestError: LocalizedError { var errorDescription: String? { "Timeout" } }

        let cached = [
            Verse(book: "Genesis", chapter: 1, verse: 1, text: "cached-1")
        ]

        let network = NetworkManagerMock(fetchChapterPage: { _, _, _, _ in
            throw TestError()
        })
        let store = VerseStoreMock(fetchChapter: { _, _, _ in cached })

        let sut = BibleBrowserViewModel(networkManager: network, verseStore: store)
        sut.selectedBookId = 1 // Genesis
        sut.selectedChapter = 1
        sut.version = "en-asv"

        sut.fetchSelectedChapter()

        let cachedSnapshot = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == Self.snapshot(cached)
        }
        XCTAssertEqual(Self.snapshot(cachedSnapshot), Self.snapshot(cached))

        // Give the task a brief chance to fail the network request.
        try await Task.sleep(nanoseconds: 50_000_000)

        let message = sut.errorMessage
        XCTAssertNil(message)

        let stillCached = sut.verses
        XCTAssertEqual(Self.snapshot(stillCached), Self.snapshot(cached))
    }

    // MARK: - Helpers

    private func waitForVerses(
        from viewModel: BibleBrowserViewModel,
        timeout: TimeInterval = 1.0,
        predicate: @escaping ([Verse]) -> Bool
    ) async throws -> [Verse] {
        let exp = expectation(description: "Wait for verses")
        var output: [Verse] = []

        viewModel.$verses
            .sink { verses in
                if predicate(verses) {
                    output = verses
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: timeout)
        return output
    }

    private func waitForErrorMessage(
        from viewModel: BibleBrowserViewModel,
        timeout: TimeInterval = 1.0,
        predicate: @escaping (String?) -> Bool
    ) async throws -> String? {
        let exp = expectation(description: "Wait for error message")
        var output: String?

        viewModel.$errorMessage
            .sink { message in
                if predicate(message) {
                    output = message
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: timeout)
        return output
    }

    private static func snapshot(_ verses: [Verse]) -> [String] {
        verses.map { verse in
            let book = verse.book ?? "nil"
            return "\(book)|\(verse.chapter)|\(verse.verse)|\(verse.text)"
        }
    }
}

// MARK: - Mocks

actor VerseStoreMock: VerseStoreProtocol {
    private let fetchChapterImpl: @Sendable (String, Int, String) async -> [Verse]
    private var upsertedVerses: [Verse] = []

    init(fetchChapter: @escaping @Sendable (String, Int, String) async -> [Verse]) {
        self.fetchChapterImpl = fetchChapter
    }

    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async -> Verse? {
        nil
    }

    func fetchChapter(book: String, chapter: Int, version: String) async -> [Verse] {
        await fetchChapterImpl(book, chapter, version)
    }

    func upsert(verse: Verse, bookFallback: String, version: String) async {
        upsertedVerses = [verse]
    }

    func upsert(verses: [Verse], bookFallback: String, chapter: Int, version: String) async {
        upsertedVerses = verses
    }

    func upsertedVersesSnapshot() async -> [Verse] {
        upsertedVerses
    }
}

actor NetworkManagerMock: NetworkManagerProtocol {
    private let fetchChapterPageImpl: @Sendable (String, Int, Int, String) async throws -> ChapterPage

    init(fetchChapterPage: @escaping @Sendable (String, Int, Int, String) async throws -> ChapterPage) {
        self.fetchChapterPageImpl = fetchChapterPage
    }

    func fetchChapter(book: String, chapter: Int, version: String) async throws -> [Verse] {
        throw NetworkError.unexpectedPayload
    }

    func fetchChapterPage(book: String, chapter: Int, totalChapters: Int, version: String) async throws -> ChapterPage {
        try await fetchChapterPageImpl(book, chapter, totalChapters, version)
    }

    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async throws -> Verse {
        throw NetworkError.unexpectedPayload
    }
}

actor AsyncGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { cont in
            waiters.append(cont)
        }
    }

    func open() {
        guard !isOpen else { return }
        isOpen = true
        let continuations = waiters
        waiters.removeAll()
        continuations.forEach { $0.resume() }
    }
}

