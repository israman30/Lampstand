//
//  BibleBrowserView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/10/26.
//

import SwiftUI

struct BibleBrowserView: View {
    @StateObject private var viewModel: BibleBrowserViewModel
    private let versions = ["en-asv", "en-kjv"]
    @State private var isShowingSearch = false
    @State private var pendingScrollToVerse: Int?
    @State private var highlightedVerse: Int?
    
    @AppStorage("lampstand.appearance")
    private var appearanceRawValue: String = LampstandAppearance.system.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        self._viewModel = StateObject(
            wrappedValue: BibleBrowserViewModel(networkManager: NetworkManager())
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        LampstandTheme.Palette.parchment,
                        LampstandTheme.Palette.parchmentTint
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollViewReader { proxy in
                    List {
                        // MARK: - Book Version { Picker ["en-asv", "en-kjv"] }
                        Section {
                            Picker("Book", selection: Binding(
                                    get: { viewModel.selectedBookId },
                                    set: { viewModel.userSelectedBook(id: $0) }
                                )
                            ) {
                                ForEach(viewModel.availableBooks) { book in
                                    Text(book.name)
                                        .font(LampstandTheme.Typography.bodyEmphasis)
                                        .foregroundStyle(LampstandTheme.Palette.ink)
                                        .tag(book.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityHint("Choose a Bible book to read")
                        } footer: {
                            if let selected = viewModel.selectedBook {
                                selectedBook(book: selected)
                            }
                        }

                        Section {
                            if viewModel.selectedBook == nil {
                                unavailableContent()
                            } else {
                                // Selected Chapter Header
                                SelectedChapterHeaderView(viewMode: viewModel, previous: {
                                    viewModel.goToPreviousChapter()
                                }, next: {
                                    viewModel.goToNextChapter()
                                })
                                // Loafing Chapter
                                if viewModel.isLoading {
                                    loadingChapter()
                                }
                                // List Cahpters
                                if let message = viewModel.errorMessage, viewModel.verses.isEmpty {
                                    ContentUnavailableView("Couldn’t load chapter", systemImage: "exclamationmark.triangle", description: Text(message))
                                } else {
                                    ForEach(viewModel.verses) { verse in
                                        VerseRow(
                                            bookName: viewModel.selectedBook?.name,
                                            chapter: viewModel.selectedChapter,
                                            verseNumber: verse.verse,
                                            text: verse.text,
                                            isHighlighted: highlightedVerse == verse.verse
                                        )
                                        .id(verse.verse)
                                        .listRowInsets(
                                            EdgeInsets(top: 6, leading: 5, bottom: 6, trailing: 5)
                                        )
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .accessibilityRotor("Verses") {
                        ForEach(viewModel.verses) { verse in
                            AccessibilityRotorEntry("Verse \(verse.verse)", id: verse.verse) {
                                pendingScrollToVerse = verse.verse
                                highlightedVerse = verse.verse
                                scrollToVerse(verse.verse, proxy: proxy)
                            }
                        }
                    }
                    .onChange(of: viewModel.verses.count) { _, _ in
                        guard let target = pendingScrollToVerse else { return }
                        pendingScrollToVerse = nil
                        highlightedVerse = target
                        // The list needs a beat to lay out new rows before ScrollViewReader can reliably scroll to them.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            scrollToVerse(target, proxy: proxy)
                        }
                        // Highlight is intentionally temporary—enough to orient the user, without staying “stuck on.”
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if highlightedVerse == target {
                                highlightedVerse = nil
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search")
                    .accessibilityHint("Find a specific Bible verse")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(
                            "Version",
                            selection: Binding(
                                get: { viewModel.version },
                                set: { viewModel.userSelectedVersion($0) }
                            )
                        ) {
                            ForEach(versions, id: \.self) { version in
                                Text(version.uppercased())
                                    .tag(version)
                                    .accessibilityLabel(LampstandAccessibility.spokenVersion(version))
                            }
                        }

                        Divider()

                        Picker("Appearance", selection: $appearanceRawValue) {
                            ForEach(LampstandAppearance.allCases) { option in
                                Label(option.title, systemImage: option.systemImage)
                                    .tag(option.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .lampstandSettingsMenuLabel()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(LampstandTheme.Palette.parchment, for: .navigationBar)
            .onChange(of: viewModel.isLoading) { _, isLoading in
                if isLoading {
                    LampstandAccessibility.announce("Loading chapter")
                }
            }
            .onChange(of: highlightedVerse) { _, verse in
                guard let verse, let book = viewModel.selectedBook?.name else { return }
                LampstandAccessibility.announce(
                    "Highlighted \(LampstandAccessibility.verseReference(book: book, chapter: viewModel.selectedChapter, verse: verse))"
                )
            }
        }
        .task {
            viewModel.fetchSelectedChapter()
        }
        .sheet(isPresented: $isShowingSearch) {
            NavigationStack {
                SearchBookView(
                    initialBook: viewModel.selectedBook?.name ?? "",
                    initialChapter: viewModel.selectedChapter,
                    initialVerse: nil,
                    initialVersion: viewModel.version
                ) { book, chapter, verse, version in
                    viewModel.navigateTo(bookName: book, chapter: chapter, version: version)
                    pendingScrollToVerse = verse
                }
            }
        }
    }

    private func scrollToVerse(_ verse: Int, proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo(verse, anchor: .top)
        } else {
            withAnimation(.easeInOut) {
                proxy.scrollTo(verse, anchor: .top)
            }
        }
    }
    
    // MARK: - Selected Book
    private func selectedBook(book selected: BibleBook) -> some View {
        Text("\(selected.chapterCount) chapters")
            .font(LampstandTheme.Typography.caption)
            .foregroundStyle(LampstandTheme.Palette.inkSecondary)
            .accessibilityLabel("\(selected.chapterCount) chapters in \(selected.name)")
    }
    
    private func unavailableContent() -> some View {
        ContentUnavailableView(
            "Select a book",
            systemImage: "book",
            description: Text("Pick a book from the menu to start reading.")
        )
    }
    
    // MARK: - Loading `Chapter`
    private func loadingChapter() -> some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading chapter…")
                .font(LampstandTheme.Typography.body)
                .foregroundStyle(LampstandTheme.Palette.inkSecondary)
        }
        .lampstandLoadingStatus("Loading chapter", isLoading: true)
    }
}

#if DEBUG
struct BibleBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        BibleBrowserView()
    }
}
#endif

// MARK: - Selected Chapter Header Section
struct SelectedChapterHeaderView: View {
    var viewModel: BibleBrowserViewModel
    var previous: () -> Void
    var next: () -> Void
    
    init(viewMode: BibleBrowserViewModel, previous: @escaping () -> Void, next: @escaping () -> Void) {
        self.viewModel = viewMode
        self.previous = previous
        self.next = next
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                previous()
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .imageScale(.medium)
            }
            .disabled(viewModel.selectedChapter <= viewModel.chapterRange.lowerBound)
            .accessibilityLabel("Previous chapter")
            .accessibilityHint(
                viewModel.selectedChapter > viewModel.chapterRange.lowerBound
                    ? "Go to chapter \(viewModel.selectedChapter - 1)"
                    : "Already at the first chapter"
            )

            Spacer()

            Text("Chapter \(viewModel.selectedChapter)")
                .font(LampstandTheme.Typography.title)
                .foregroundStyle(LampstandTheme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(
                    "Chapter \(viewModel.selectedChapter) of \(viewModel.selectedBook?.name ?? "")"
                )

            Spacer()

            Button {
                next()
            } label: {
                Label("Next", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .imageScale(.medium)
            }
            .disabled(viewModel.selectedChapter >= viewModel.chapterRange.upperBound)
            .accessibilityLabel("Next chapter")
            .accessibilityHint(
                viewModel.selectedChapter < viewModel.chapterRange.upperBound
                    ? "Go to chapter \(viewModel.selectedChapter + 1)"
                    : "Already at the last chapter"
            )
        }
        .buttonStyle(.borderedProminent)
    }
}
