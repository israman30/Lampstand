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

    init() {
        self._viewModel = StateObject(wrappedValue: BibleBrowserViewModel(networkManager: NetworkManager()))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Books") {
                    Picker("Book", selection: $viewModel.selectedBookId) {
                        ForEach(viewModel.availableBooks) { book in
                            Text(book.name).tag(book.id)
                        }
                    }
                    .pickerStyle(.menu)

                    if let selected = viewModel.selectedBook {
                        Text("\(selected.chapterCount) chapters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Chapter") {
                    if viewModel.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Loading chapter…")
                        }
                    } else if viewModel.selectedBook == nil {
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
                        } else if let message = viewModel.errorMessage {
                            ContentUnavailableView("Couldn’t load chapter", systemImage: "exclamationmark.triangle", description: Text(message))
                        } else {
                            ForEach(viewModel.verses) { verse in
                                VerseRow(verseNumber: verse.verse, text: verse.text)
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Version", selection: $viewModel.version) {
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
        .onChange(of: viewModel.selectedBookId) { _, _ in
            viewModel.selectBook(id: viewModel.selectedBookId)
        }
        .onChange(of: viewModel.version) { _, _ in
            viewModel.fetchSelectedChapter()
        }
    }
}

private struct VerseRow: View {
    let verseNumber: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(verseNumber)")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 22, alignment: .trailing)

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct BibleBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        BibleBrowserView()
    }
}
#endif

