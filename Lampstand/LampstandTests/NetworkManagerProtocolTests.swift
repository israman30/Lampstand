import XCTest
@testable import Lampstand

@MainActor
final class NetworkManagerProtocolTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolStub.self)
        URLProtocolStub.reset()
    }

    override func tearDown() {
        URLProtocolStub.reset()
        URLProtocol.unregisterClass(URLProtocolStub.self)
        super.tearDown()
    }

    func test_fetchChapter_buildsExpectedURL_andDecodesVerses() async throws {
        let baseURL = try XCTUnwrap(URL(string: "https://example.com/bibles"))
        let sut = NetworkManager(baseURL: baseURL)

        let expectedVerse1 = Verse(book: "1 Samuel", chapter: 3, verse: 1, text: "Test verse 1")
        let expectedVerse2 = Verse(book: "1 Samuel", chapter: 3, verse: 2, text: "Test verse 2")
        let payload = """
        {
          "verses": [
            { "book": "1 Samuel", "chapter": 3, "verse": 1, "text": "Test verse 1" },
            { "book": "1 Samuel", "chapter": 3, "verse": 2, "text": "Test verse 2" }
          ]
        }
        """.data(using: .utf8)!

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            XCTAssertEqual(url.host, "example.com")
            XCTAssertEqual(url.path, "/bibles/en-asv/books/1-samuel/chapters/3.json")

            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, payload)
        }
        
        let verses = try await sut.fetchChapter(book: "1 Samuel", chapter: 3, version: "en asv")

        XCTAssertEqual(verses.count, 2)

        let v0 = verses[0]
        let v1 = verses[1]

        let v0Book = v0.book
        let v0Chapter = v0.chapter
        let v0Verse = v0.verse
        let v0Text = v0.text

        let v1Book = v1.book
        let v1Chapter = v1.chapter
        let v1Verse = v1.verse
        let v1Text = v1.text

        let e1Book = expectedVerse1.book
        let e1Chapter = expectedVerse1.chapter
        let e1Verse = expectedVerse1.verse
        let e1Text = expectedVerse1.text

        let e2Book = expectedVerse2.book
        let e2Chapter = expectedVerse2.chapter
        let e2Verse = expectedVerse2.verse
        let e2Text = expectedVerse2.text

        XCTAssertEqual(v0Book, e1Book)
        XCTAssertEqual(v0Chapter, e1Chapter)
        XCTAssertEqual(v0Verse, e1Verse)
        XCTAssertEqual(v0Text, e1Text)

        XCTAssertEqual(v1Book, e2Book)
        XCTAssertEqual(v1Chapter, e2Chapter)
        XCTAssertEqual(v1Verse, e2Verse)
        XCTAssertEqual(v1Text, e2Text)
    }

    func test_fetchChapter_throwsInvalidURL_forEmptyInputs() async {
        let baseURL = URL(string: "https://example.com/bibles")!
        let sut = NetworkManager(baseURL: baseURL)

        do {
            _ = try await sut.fetchChapter(book: " ", chapter: 1, version: "en-asv")
            XCTFail("Expected to throw")
        } catch let error as NetworkError {
            if case .invalidURL = error {
                return
            }
            XCTFail("Expected NetworkError.invalidURL, got \(error)")
        } catch {
            XCTFail("Expected NetworkError.invalidURL, got \(error)")
        }
    }

    func test_fetchChapter_throwsHttpStatus_onNon2xx() async {
        let baseURL = URL(string: "https://example.com/bibles")!
        let sut = NetworkManager(baseURL: baseURL)

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchChapter(book: "Genesis", chapter: 1, version: "en-asv")
            XCTFail("Expected to throw")
        } catch let error as NetworkError {
            if case .httpStatus(let code) = error {
                XCTAssertEqual(code, 404)
                return
            }
            XCTFail("Expected NetworkError.httpStatus(404), got \(error)")
        } catch {
            XCTFail("Expected NetworkError.httpStatus(404), got \(error)")
        }
    }

    func test_fetchVerse_decodesPlainVerse() async throws {
        let baseURL = URL(string: "https://example.com/bibles")!
        let sut = NetworkManager(baseURL: baseURL)

        let payload = """
        { "book": "Genesis", "chapter": 1, "verse": 1, "text": "In the beginning..." }
        """.data(using: .utf8)!

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            XCTAssertEqual(url.path, "/bibles/en-asv/books/genesis/chapters/1/verses/1.json")
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, payload)
        }

        let verse = try await sut.fetchVerse(book: "Genesis", chapter: 1, verse: 1, version: "en-asv")

        let actualBook = verse.book
        let actualChapter = verse.chapter
        let actualVerse = verse.verse
        let actualText = verse.text

        XCTAssertEqual(actualBook, "Genesis")
        XCTAssertEqual(actualChapter, 1)
        XCTAssertEqual(actualVerse, 1)
        XCTAssertEqual(actualText, "In the beginning...")
    }

    func test_fetchVerse_decodesWrappedVerse() async throws {
        let baseURL = URL(string: "https://example.com/bibles")!
        let sut = NetworkManager(baseURL: baseURL)

        let payload = """
        {
          "verse": { "book": "Genesis", "chapter": 1, "verse": 2, "text": "And the earth..." }
        }
        """.data(using: .utf8)!

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, payload)
        }

        let verse = try await sut.fetchVerse(book: "Genesis", chapter: 1, verse: 2, version: "en-asv")

        let actualBook = verse.book ?? "Genesis"
        let actualChapter = verse.chapter
        let actualVerse = verse.verse
        let actualText = verse.text

        XCTAssertEqual(actualBook, "Genesis")
        XCTAssertEqual(actualChapter, 1)
        XCTAssertEqual(actualVerse, 2)
        XCTAssertEqual(actualText, "And the earth...")
    }

    func test_fetchVerse_fillsMissingChapterFromRequest() async throws {
        let baseURL = URL(string: "https://example.com/bibles")!
        let sut = NetworkManager(baseURL: baseURL)

        let payload = """
        { "book": "John", "verse": 16, "text": "For God so loved the world..." }
        """.data(using: .utf8)!

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, payload)
        }

        let verse = try await sut.fetchVerse(book: "John", chapter: 3, verse: 16, version: "en-asv")

        XCTAssertEqual(verse.book, "John")
        XCTAssertEqual(verse.chapter, 3)
        XCTAssertEqual(verse.verse, 16)
        XCTAssertEqual(verse.text, "For God so loved the world...")
    }

    func test_fetchVerse_throwsUnexpectedPayload_forUnknownJSON() async {
        let baseURL = URL(string: "https://example.com/bibles")!
        let sut = NetworkManager(baseURL: baseURL)

        let payload = """
        { "unexpected": true }
        """.data(using: .utf8)!

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, payload)
        }

        do {
            _ = try await sut.fetchVerse(book: "Genesis", chapter: 1, verse: 1, version: "en-asv")
            XCTAssertNil(nil)
        } catch let error as NetworkError {
            if case .unexpectedPayload = error {
                return
            }
            XCTFail("Expected NetworkError.unexpectedPayload, got \(error)")
        } catch {
            XCTFail("Expected NetworkError.unexpectedPayload, got \(error)")
        }
    }

    func test_fetchChapterPage_includesPreviousAndNextChapterHints() async throws {
        let baseURL = URL(string: "https://example.com/bibles")!
        let sut = NetworkManager(baseURL: baseURL)

        let payload = """
        {
          "verses": [
            { "book": "Genesis", "chapter": 2, "verse": 1, "text": "Thus the heavens..." }
          ]
        }
        """.data(using: .utf8)!

        URLProtocolStub.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, payload)
        }

        let page = try await sut.fetchChapterPage(book: "Genesis", chapter: 2, totalChapters: 3, version: "en-asv")

        let actualBook = page.book
        let actualChapter = page.chapter
        let actualPrevious = page.previousChapter
        let actualNext = page.nextChapter
        let actualVersesCount = page.verses.count
        let firstVerseChapter = page.verses.first?.chapter
        let firstVerseVerse = page.verses.first?.verse

        XCTAssertEqual(actualBook, "Genesis")
        XCTAssertEqual(actualChapter, 2)
        XCTAssertEqual(actualPrevious, 1)
        XCTAssertEqual(actualNext, 3)
        XCTAssertEqual(actualVersesCount, 1)
        XCTAssertEqual(firstVerseChapter, 2)
        XCTAssertEqual(firstVerseVerse, 1)
    }
}

// MARK: - URLProtocol Stub

private final class URLProtocolStub: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        requestHandler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        // Only intercept requests sent to our test host so we don't interfere with unrelated system traffic.
        return request.url?.host == "example.com"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}

