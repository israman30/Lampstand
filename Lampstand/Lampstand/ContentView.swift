//
//  ContentView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
// https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1.json

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel: BookViewModel

    init() {
        self._viewModel = StateObject(wrappedValue: BookViewModel(networkManager: NetworkManager()))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading…")
                } else if let message = viewModel.errorMessage {
                    ContentUnavailableView("Couldn’t load", systemImage: "exclamationmark.triangle", description: Text(message))
                } else if viewModel.verses.isEmpty {
                    ContentUnavailableView("No verses", systemImage: "book", description: Text("Try searching “John 3”."))
                } else {
                    List(viewModel.verses) { verse in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Verse \(verse.verse)")
                                .font(.headline)
                            Text(verse.text)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
        }
        .searchable(text: $viewModel.searchText, prompt: "Book + chapter (e.g. John 3)")
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .task {
            await viewModel.fetchVerses()
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
