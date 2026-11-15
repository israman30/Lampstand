import XCTest
import Combine
@testable import Lampstand

@MainActor
final class BookViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_bookTextChange_resetsDependentState() async throws {
        let fresh = Verse(book: "GENESIS", chapter: 1, verse: 1, text: "fresh")
        let network = BookNetworkManagerMock(fetchVerse: { _, _, _, _ in fresh })
        let store = BookVerseStoreMock(fetchVerse: { _, _, _, _ in nil })

        let sut = BookViewModel(networkManager: network, verseStore: store)

        // First, drive the VM into a "non-default" state by triggering a fetch.
        sut.bookText = "Genesis"
        sut.chapterText = "1"
        sut.verseText = "1"

        _ = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == ["GENESIS|1|1|fresh"]
        }

        // Now change the book; this should reset dependent inputs/outputs immediately.
        sut.chapterText = "3"
        sut.verseText = "16"
        sut.errorMessage = "Old error"
        sut.isLoading = true

        sut.bookText = "John"

        // Allow Combine sinks to run.
        await Task.yield()

        let chapterText = sut.chapterText
        let verseText = sut.verseText
        let versesCount = sut.verses.count
        let errorMessage = sut.errorMessage
        let isLoading = sut.isLoading
        let navigationTitle = sut.navigationTitle

        XCTAssertEqual(chapterText, "")
        XCTAssertEqual(verseText, "")
        XCTAssertEqual(versesCount, 0)
        XCTAssertNil(errorMessage)
        XCTAssertEqual(isLoading, false)
        XCTAssertEqual(navigationTitle, "Lampstand")
    }

    func test_debouncedVerseText_triggersNetworkFetch_andUpsert_andSetsNavigationTitle() async throws {
        let fresh = Verse(book: "GENESIS", chapter: 1, verse: 1, text: "fresh")
        let network = BookNetworkManagerMock(fetchVerse: { _, _, _, _ in fresh })
        let store = BookVerseStoreMock(fetchVerse: { _, _, _, _ in nil })

        let sut = BookViewModel(networkManager: network, verseStore: store)

        sut.bookText = "genesis"
        sut.chapterText = "1"
        sut.verseText = "1"

        // Debounce in `BookViewModel` is 350ms.
        let verses = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == ["GENESIS|1|1|fresh"]
        }

        XCTAssertEqual(Self.snapshot(verses), ["GENESIS|1|1|fresh"])

        let title = sut.navigationTitle
        XCTAssertEqual(title, "GENESIS 1:1")

        let upserted = await store.upsertedVerseSnapshot()
        let upsertedSnapshot = upserted.map { Self.snapshot([$0]) } ?? []
        XCTAssertEqual(upsertedSnapshot, ["GENESIS|1|1|fresh"])

        let calls = await network.fetchVerseCallCount()
        XCTAssertEqual(calls, 1)
    }

    func test_cacheHit_setsCachedImmediately_thenRefreshesFromNetwork() async throws {
        let cached = Verse(book: "Genesis", chapter: 1, verse: 1, text: "cached")
        let fresh = Verse(book: "Genesis", chapter: 1, verse: 1, text: "fresh")

        let gate = BookAsyncGate()

        let network = BookNetworkManagerMock(fetchVerse: { _, _, _, _ in
            await gate.wait()
            return fresh
        })
        let store = BookVerseStoreMock(fetchVerse: { _, _, _, _ in cached })

        let sut = BookViewModel(networkManager: network, verseStore: store)
        sut.bookText = "Genesis"
        sut.chapterText = "1"
        sut.verseText = "1"

        let cachedVerses = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == ["Genesis|1|1|cached"]
        }
        XCTAssertEqual(Self.snapshot(cachedVerses), ["Genesis|1|1|cached"])

        await gate.open()

        let freshVerses = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == ["Genesis|1|1|fresh"]
        }
        XCTAssertEqual(Self.snapshot(freshVerses), ["Genesis|1|1|fresh"])

        let message = sut.errorMessage
        XCTAssertNil(message)
    }

    func test_cacheEmpty_networkFailure_setsError_andKeepsNavigationTitleOverride() async throws {
        struct TestError: LocalizedError { var errorDescription: String? { "Timeout" } }

        let network = BookNetworkManagerMock(fetchVerse: { _, _, _, _ in
            throw TestError()
        })
        let store = BookVerseStoreMock(fetchVerse: { _, _, _, _ in nil })

        let sut = BookViewModel(networkManager: network, verseStore: store)
        sut.bookText = "1 samuel"
        sut.chapterText = "3"
        sut.verseText = "1"

        let message = try await waitForErrorMessage(from: sut) { $0 == "Timeout" }
        XCTAssertEqual(message, "Timeout")

        let versesCount = sut.verses.count
        XCTAssertEqual(versesCount, 0)

        let title = sut.navigationTitle
        XCTAssertEqual(title, "1 Samuel 3:1")
    }

    func test_networkVerseMissingChapter_resolvesChapterForDisplay() async throws {
        let fresh = Verse(book: "John", chapter: 0, verse: 16, text: "For God so loved the world...")
        let network = BookNetworkManagerMock(fetchVerse: { _, _, _, _ in fresh })
        let store = BookVerseStoreMock(fetchVerse: { _, _, _, _ in nil })

        let sut = BookViewModel(networkManager: network, verseStore: store)
        sut.bookText = "John"
        sut.chapterText = "3"
        sut.verseText = "16"

        let verses = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == ["John|3|16|For God so loved the world..."]
        }

        XCTAssertEqual(Self.snapshot(verses), ["John|3|16|For God so loved the world..."])
        XCTAssertEqual(sut.navigationTitle, "John 3:16")
    }

    func test_versionChange_triggersAnotherFetch() async throws {
        let gate1 = BookAsyncGate()
        let gate2 = BookAsyncGate()
        let asv = Verse(book: "Genesis", chapter: 1, verse: 1, text: "asv")
        let kjv = Verse(book: "Genesis", chapter: 1, verse: 1, text: "kjv")
        let network = BookNetworkManagerMock(fetchVerse: { _, _, _, version in
            if version == "en-asv" {
                await gate1.wait()
                return asv
            } else {
                await gate2.wait()
                return kjv
            }
        })
        let store = BookVerseStoreMock(fetchVerse: { _, _, _, _ in nil })

        let sut = BookViewModel(networkManager: network, verseStore: store)
        sut.bookText = "Genesis"
        sut.chapterText = "1"
        sut.verseText = "1"

        await gate1.open()

        _ = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == ["Genesis|1|1|asv"]
        }

        sut.version = "en-kjv"

        await gate2.open()

        _ = try await waitForVerses(from: sut) { verses in
            Self.snapshot(verses) == ["Genesis|1|1|kjv"]
        }

        let calls = await network.fetchVerseCallCount()
        XCTAssertEqual(calls, 2)
    }

    // MARK: - Helpers

    private func waitForVerses(
        from viewModel: BookViewModel,
        timeout: TimeInterval = 2.0,
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
        from viewModel: BookViewModel,
        timeout: TimeInterval = 2.0,
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

private actor BookVerseStoreMock: VerseStoreProtocol {
    private let fetchVerseImpl: @Sendable (String, Int, Int, String) async -> Verse?
    private var upsertedVerse: Verse?

    init(fetchVerse: @escaping @Sendable (String, Int, Int, String) async -> Verse?) {
        self.fetchVerseImpl = fetchVerse
    }

    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async -> Verse? {
        await fetchVerseImpl(book, chapter, verse, version)
    }

    func fetchChapter(book: String, chapter: Int, version: String) async -> [Verse] {
        []
    }

    func upsert(verse: Verse, bookFallback: String, version: String) async {
        upsertedVerse = verse
    }

    func upsert(verses: [Verse], bookFallback: String, chapter: Int, version: String) async { }

    func upsertedVerseSnapshot() async -> Verse? {
        upsertedVerse
    }
}

private actor BookNetworkManagerMock: NetworkManagerProtocol {
    private let fetchVerseImpl: @Sendable (String, Int, Int, String) async throws -> Verse
    private var fetchVerseCalls: Int = 0

    init(fetchVerse: @escaping @Sendable (String, Int, Int, String) async throws -> Verse) {
        self.fetchVerseImpl = fetchVerse
    }

    func fetchChapter(book: String, chapter: Int, version: String) async throws -> [Verse] {
        throw NetworkError.unexpectedPayload
    }

    func fetchChapterPage(book: String, chapter: Int, totalChapters: Int, version: String) async throws -> ChapterPage {
        throw NetworkError.unexpectedPayload
    }

    func fetchVerse(book: String, chapter: Int, verse: Int, version: String) async throws -> Verse {
        fetchVerseCalls += 1
        return try await fetchVerseImpl(book, chapter, verse, version)
    }

    func fetchVerseCallCount() async -> Int {
        fetchVerseCalls
    }
}

private actor BookAsyncGate {
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

