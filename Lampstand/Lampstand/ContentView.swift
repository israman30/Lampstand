//
//  ContentView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
// https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1.json

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: BookViewModel
    private let versions = ["en-asv", "en-kjv"]

    init() {
        self._viewModel = StateObject(wrappedValue: BookViewModel(networkManager: NetworkManager()))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Search") {
                    TextField("Book (e.g. John, 1 John)", text: $viewModel.bookText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

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

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
