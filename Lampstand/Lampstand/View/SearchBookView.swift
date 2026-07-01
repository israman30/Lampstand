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
    @AppStorage("lampstand.appearance")
    private var appearanceRawValue: String = LampstandAppearance.system.rawValue

    init(
        initialBook: String = "",
        initialChapter: Int = 1,
        initialVerse: Int? = nil,
        initialVersion: String = "en-asv",
        networkManager: NetworkManagerProtocol = NetworkManager(),
        verseStore: VerseStoreProtocol? = nil,
        onOpenInReader: @escaping (_ book: String, _ chapter: Int, _ verse: Int, _ version: String) -> Void = { _, _, _, _ in }
    ) {
        let viewModel = BookViewModel(networkManager: networkManager, verseStore: verseStore)
        viewModel.bookText = initialBook
        viewModel.chapterText = initialChapter > 0 ? String(initialChapter) : ""
        viewModel.verseText = initialVerse.map(String.init) ?? ""
        viewModel.version = initialVersion
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onOpenInReader = onOpenInReader
    }
    
    var body: some View {
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

            List {
                // MARK: - Query Verse section with user { Picker, TextField } selection
                VerseSelectionView(viewModel: viewModel)
                // MARK: - Section Result after query Verse
                Section("Result") {
                    if viewModel.isLoading {
                        loadingResult("Searching…")
                    }

                    if let message = viewModel.errorMessage,
                        viewModel.displayedVerse == nil {
                        errorResult(with: message)
                    } else if let verse = viewModel.displayedVerse {
                        verseResult(verse: verse)
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
                        .accessibilityHint("Opens this verse in the main Bible reader")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(viewModel.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
                .accessibilityHint("Closes verse search")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // MARK: - Bible Version Selection { Menu ["en-asv", "en-kjv"] }
                    Picker("Version", selection: $viewModel.version) {
                        ForEach(versions, id: \.self) { version in
                            Text(version.uppercased())
                                .tag(version)
                                .accessibilityLabel(
                                    LampstandAccessibility.spokenVersion(version)
                                )
                        }
                    }

                    Divider()
                    // MARK: - UI Apperance { System, Light, Dark }
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
                LampstandAccessibility.announce("Searching for verse")
            }
        }
        .onChange(of: viewModel.displayedVerse?.id) { _, verseId in
            guard verseId != nil else { return }
            LampstandAccessibility.announce("Verse found")
        }
    }
    
    // Laoding Result
    private func loadingResult(_ message: String) -> some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(LampstandTheme.Typography.body)
                .foregroundStyle(LampstandTheme.Palette.inkSecondary)
        }
        .lampstandLoadingStatus("Searching for verse", isLoading: true)
    }
    
    // Error Result
    private func errorResult(with message: String) -> some View {
        ContentUnavailableView(
            "Couldn’t load",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
    
    // Verse Query Result
    private func verseResult(verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(verse.book ?? viewModel.bookText) \(verse.chapter):\(verse.verse)")
                .verseTextStyle(
                    font: LampstandTheme.Typography.headline,
                    color: LampstandTheme.Palette.ink
                )
                .accessibilityAddTraits(.isHeader)
                .accessibilityHidden(true)

            Text(verse.text)
                .verseTextStyle(
                    font: LampstandTheme.Typography.body,
                    color: LampstandTheme.Palette.ink
                )
                .textSelection(.enabled)
                .lineSpacing(2)
                .accessibilityHidden(true)
        }
        .lampstandCard()
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            LampstandAccessibility.verseLabel(
                book: verse.book ?? viewModel.bookText,
                chapter: verse.chapter,
                verse: verse.verse,
                text: verse.text
            )
        )
    }
}

#if DEBUG
struct SearchBookView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SearchBookView(
                initialBook: "John",
                initialChapter: 3,
                initialVerse: 16,
                initialVersion: "en-asv"
            )
        }
    }
}
#endif

struct VerseSelectionView: View {
    @State var viewModel: BookViewModel
    var body: some View {
        Picker("Book", selection: $viewModel.bookText) {
            Text("Select a book").tag("")
            ForEach(viewModel.availableBooks, id: \.self) { book in
                Text(book).tag(book)
            }
        }
        .pickerStyle(.menu)
        .accessibilityHint("Choose the Bible book to search")

        TextField("Chapter (e.g. 3)", text: $viewModel.chapterText)
            .keyboardType(.numberPad)
            .disabled(!viewModel.chapterEnabled)
            .accessibilityLabel("Chapter")
            .accessibilityHint("Enter the chapter number")

        TextField("Verse (e.g. 16)", text: $viewModel.verseText)
            .keyboardType(.numberPad)
            .disabled(!viewModel.verseEnabled)
            .accessibilityLabel("Verse")
            .accessibilityHint("Enter the verse number")
    }
}
