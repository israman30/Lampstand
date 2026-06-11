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

    init() {
        self._viewModel = StateObject(wrappedValue: BibleBrowserViewModel(networkManager: NetworkManager()))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Section {
                        Picker(
                            "Book",
                            selection: Binding(
                                get: { viewModel.selectedBookId },
                                set: { viewModel.userSelectedBook(id: $0) }
                            )
                        ) {
                            ForEach(viewModel.availableBooks) { book in
                                Text(book.name).tag(book.id)
                            }
                        }
                        .pickerStyle(.menu)
                    } footer: {
                        if let selected = viewModel.selectedBook {
                            Text("\(selected.chapterCount) chapters")
                                .font(.caption)
                                .foregroundStyle(.primary)
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
                                Button("Prev") {
                                    viewModel.goToPreviousChapter()
                                }
                                .disabled(viewModel.selectedChapter <= viewModel.chapterRange.lowerBound)

                                Spacer()

                                Text("Chapter \(viewModel.selectedChapter)")
                                    .font(.headline)

                                Spacer()

                                Button("Next") {
                                    viewModel.goToNextChapter()
                                }
                                .disabled(viewModel.selectedChapter >= viewModel.chapterRange.upperBound)
                            }
                            .buttonStyle(.bordered)

                            if viewModel.isLoading {
                                HStack(spacing: 12) {
                                    ProgressView()
                                    Text("Loading chapter…")
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
                                }
                            }
                        }
                    }
                }
                .onChange(of: viewModel.verses.count) { _, _ in
                    guard let target = pendingScrollToVerse else { return }
                    pendingScrollToVerse = nil
                    highlightedVerse = target
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(target, anchor: .top)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if highlightedVerse == target {
                            highlightedVerse = nil
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
                    } label: {
                        Text(viewModel.version.uppercased())
                            .font(.subheadline)
                    }
                }
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
}

private struct VerseRow: View {
    let verseNumber: Int
    let text: String
    let isHighlighted: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(verseNumber)")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 22, alignment: .trailing)

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 0.5)
        .padding(.horizontal, 2)
        .background(isHighlighted ? Color.yellow.opacity(0.18) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#if DEBUG
struct BibleBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        BibleBrowserView()
    }
}
#endif

