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
                        } footer: {
                            if let selected = viewModel.selectedBook {
                                Text("\(selected.chapterCount) chapters")
                                    .font(LampstandTheme.Typography.caption)
                                    .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                            }
                        }

                        Section {
                            if viewModel.selectedBook == nil {
                                ContentUnavailableView(
                                    "Select a book",
                                    systemImage: "book",
                                    description: Text("Pick a book from the menu to start reading.")
                                )
                            } else {
                                HStack(spacing: 12) {
                                    Button {
                                        viewModel.goToPreviousChapter()
                                    } label: {
                                        Label("Previous", systemImage: "chevron.left")
                                            .labelStyle(.iconOnly)
                                            .imageScale(.medium)
                                    }
                                    .disabled(viewModel.selectedChapter <= viewModel.chapterRange.lowerBound)

                                    Spacer()

                                    Text("Chapter \(viewModel.selectedChapter)")
                                        .font(LampstandTheme.Typography.title)
                                        .foregroundStyle(LampstandTheme.Palette.ink)

                                    Spacer()

                                    Button {
                                        viewModel.goToNextChapter()
                                    } label: {
                                        Label("Next", systemImage: "chevron.right")
                                            .labelStyle(.iconOnly)
                                            .imageScale(.medium)
                                    }
                                    .disabled(viewModel.selectedChapter >= viewModel.chapterRange.upperBound)
                                }
                                .buttonStyle(.borderedProminent)

                                if viewModel.isLoading {
                                    HStack(spacing: 12) {
                                        ProgressView()
                                        Text("Loading chapter…")
                                            .font(LampstandTheme.Typography.body)
                                            .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                                    }
                                }

                                if let message = viewModel.errorMessage, viewModel.verses.isEmpty {
                                    ContentUnavailableView("Couldn’t load chapter", systemImage: "exclamationmark.triangle", description: Text(message))
                                } else {
                                    ForEach(viewModel.verses) { verse in
                                        VerseRow(
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
                    .onChange(of: viewModel.verses.count) { _, _ in
                        guard let target = pendingScrollToVerse else { return }
                        pendingScrollToVerse = nil
                        highlightedVerse = target
                        // The list needs a beat to lay out new rows before ScrollViewReader can reliably scroll to them.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo(target, anchor: .top)
                            }
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
                            ForEach(versions, id: \.self) { v in
                                Text(v.uppercased()).tag(v)
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
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(LampstandTheme.Palette.parchment, for: .navigationBar)
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
}

private struct VerseRow: View {
    let verseNumber: Int
    let text: String
    let isHighlighted: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(verseNumber)")
                .font(LampstandTheme.Typography.verseNumber)
                .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(LampstandTheme.Palette.stroke.opacity(0.9)))

            Text(text)
                .font(LampstandTheme.Typography.body)
                .foregroundStyle(LampstandTheme.Palette.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .lampstandCard(isHighlighted: isHighlighted)
    }
}

#if DEBUG
struct BibleBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        BibleBrowserView()
    }
}
#endif

