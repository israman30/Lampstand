//
//  SearchBookView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import SwiftUI

struct SearchBookView: View {
    @StateObject private var viewModel: BookViewModel
    private let versions = ["en-asv", "en-kjv"]

    init() {
        self._viewModel = StateObject(wrappedValue: BookViewModel(networkManager: NetworkManager()))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Search") {
                    Picker("Book", selection: $viewModel.bookText) {
                        Text("Select a book").tag("")
                        ForEach(viewModel.availableBooks, id: \.self) { book in
                            Text(book).tag(book)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Chapter (e.g. 3)", text: $viewModel.chapterText)
                        .keyboardType(.numberPad)
                        .disabled(!viewModel.chapterEnabled)

                    TextField("Verse (e.g. 16)", text: $viewModel.verseText)
                        .keyboardType(.numberPad)
                        .disabled(!viewModel.verseEnabled)
                }

                Section("Result") {
                    if viewModel.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Searching…")
                        }
                    } else if let message = viewModel.errorMessage {
                        ContentUnavailableView("Couldn’t load", systemImage: "exclamationmark.triangle", description: Text(message))
                    } else if let verse = viewModel.displayedVerse {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Verse \(verse.verse)")
                                .font(.headline)
                            Text(verse.text)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    } else {
                        ContentUnavailableView(
                            viewModel.placeholderTitle,
                            systemImage: "magnifyingglass",
                            description: Text(viewModel.placeholderMessage)
                        )
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Version", selection: $viewModel.version) {
                            ForEach(versions, id: \.self) { v in
                                Text(v.uppercased())
                                    .tag(v)
                            }
                        }
                    } label: {
                        Text(viewModel.version.uppercased())
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}

#Preview {
    SearchBookView()
}
