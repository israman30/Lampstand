//
//  BibleView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import SwiftUI

struct BibleView: View {
    @StateObject private var viewModel: BibleViewModel
    private let versions = ["en-asv", "en-kjv"]

    init() {
        self._viewModel = StateObject(wrappedValue: BibleViewModel(networkManager: NetworkManager()))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Chapter", selection: $viewModel.selectedChapter) {
                        ForEach(1...viewModel.totalChapters, id: \.self) { chapter in
                            Text("Chapter \(chapter)").tag(chapter)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(viewModel.book)
                }

                Section("Text") {
                    if viewModel.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Loading chapter…")
                        }
                    } else if let message = viewModel.errorMessage {
                        ContentUnavailableView("Couldn’t load chapter", systemImage: "exclamationmark.triangle", description: Text(message))
                    } else {
                        ForEach(viewModel.verses) { verse in
                            HStack(alignment: .top) {
                                Text("\(verse.verse)")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                Text(verse.text)
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("\(viewModel.book) \(viewModel.selectedChapter)")
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
        .onChange(of: viewModel.selectedChapter) { _, _ in
            viewModel.fetchSelectedChapter()
        }
        .onChange(of: viewModel.version) { _, _ in
            viewModel.fetchSelectedChapter()
        }
    }
}

#if DEBUG
struct BibleView_Previews: PreviewProvider {
    static var previews: some View {
        BibleView()
    }
}
#endif

