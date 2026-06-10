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
                            VerseRow(verseNumber: verse.verse, text: verse.text)
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
struct BibleView_Previews: PreviewProvider {
    static var previews: some View {
        BibleView()
    }
}
#endif

