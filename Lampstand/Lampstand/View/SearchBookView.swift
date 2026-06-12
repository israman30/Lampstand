//
//  SearchBookView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import SwiftUI

struct SearchBookView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BookViewModel
    private let versions = ["en-asv", "en-kjv"]
    private let onOpenInReader: (_ book: String, _ chapter: Int, _ verse: Int, _ version: String) -> Void
    @AppStorage("lampstand.appearance") private var appearanceRawValue: String = LampstandAppearance.system.rawValue

    init(
        initialBook: String = "",
        initialChapter: Int = 1,
        initialVerse: Int? = nil,
        initialVersion: String = "en-asv",
        networkManager: NetworkManagerProtocol = NetworkManager(),
        verseStore: VerseStoreProtocol? = nil,
        onOpenInReader: @escaping (_ book: String, _ chapter: Int, _ verse: Int, _ version: String) -> Void = { _, _, _, _ in }
    ) {
        let vm = BookViewModel(networkManager: networkManager, verseStore: verseStore)
        vm.bookText = initialBook
        vm.chapterText = initialChapter > 0 ? String(initialChapter) : ""
        vm.verseText = initialVerse.map(String.init) ?? ""
        vm.version = initialVersion
        self._viewModel = StateObject(wrappedValue: vm)
        self.onOpenInReader = onOpenInReader
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [LampstandTheme.Palette.parchment, LampstandTheme.Palette.parchmentTint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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
                                .font(LampstandTheme.Typography.body)
                                .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                        }
                    }

                    if let message = viewModel.errorMessage, viewModel.displayedVerse == nil {
                        ContentUnavailableView("Couldn’t load", systemImage: "exclamationmark.triangle", description: Text(message))
                    } else if let verse = viewModel.displayedVerse {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(verse.book ?? viewModel.bookText) \(verse.chapter):\(verse.verse)")
                                .font(LampstandTheme.Typography.headline)
                                .foregroundStyle(LampstandTheme.Palette.ink)

                            Text(verse.text)
                                .font(LampstandTheme.Typography.body)
                                .foregroundStyle(LampstandTheme.Palette.ink)
                                .lineSpacing(2)
                        }
                        .lampstandCard()
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ContentUnavailableView(
                            viewModel.placeholderTitle,
                            systemImage: "magnifyingglass",
                            description: Text(viewModel.placeholderMessage)
                        )
                    }
                }

                if let verse = viewModel.displayedVerse {
                    Section {
                        Button {
                            let book = verse.book ?? viewModel.bookText.trimmingCharacters(in: .whitespacesAndNewlines)
                            onOpenInReader(book, verse.chapter, verse.verse, viewModel.version)
                            dismiss()
                        } label: {
                            Label("Open in Reader", systemImage: "book")
                                .font(LampstandTheme.Typography.bodyEmphasis)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(viewModel.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Version", selection: $viewModel.version) {
                        ForEach(versions, id: \.self) { v in
                            Text(v.uppercased())
                                .tag(v)
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
}

#if DEBUG
struct SearchBookView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SearchBookView(initialBook: "John", initialChapter: 3, initialVerse: 16, initialVersion: "en-asv")
        }
    }
}
#endif
