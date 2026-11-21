//
//  VerseSelectionView.swift
//  Lampstand
//
//  Created by Israel Manzo on 7/1/26.
//

import SwiftUI

struct VerseSelectionView: View {
    @ObservedObject var viewModel: BookViewModel

    var body: some View {
        Section("Search Verse") {
            Picker("Book", selection: $viewModel.bookText) {
                Text("Select a book").tag("")
                ForEach(viewModel.availableBooks, id: \.self) { book in
                    Text(book).tag(book)
                }
            }
            .pickerStyle(.menu)
            .accessibilityHint("Choose the Bible book to search")

            if !viewModel.bookText.isEmpty {
                Text(viewModel.bookText)
                    .font(LampstandTheme.Typography.caption)
                    .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Selected book: \(viewModel.bookText)")
            }

            TextField(
                "Chapter (e.g. 3)",
                text: Binding(
                    get: { viewModel.chapterText },
                    set: { viewModel.updateChapter($0) }
                )
            )
            .keyboardType(.numberPad)
            .disabled(!viewModel.chapterEnabled)
            .submitLabel(.next)
            .accessibilityLabel("Chapter")
            .accessibilityHint("Enter the chapter number")

            TextField(
                "Verse (e.g. 16)",
                text: Binding(
                    get: { viewModel.verseText },
                    set: { viewModel.updateVerse($0) }
                )
            )
            .keyboardType(.numberPad)
            .disabled(!viewModel.verseEnabled)
            .submitLabel(.search)
            .accessibilityLabel("Verse")
            .accessibilityHint("Enter the verse number")

            if let message = viewModel.searchValidationMessage {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(LampstandTheme.Typography.caption)
                    .foregroundStyle(LampstandTheme.Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(message)
            }
        }
    }
}

#Preview {
    VerseSelectionView(viewModel: .init(networkManager: NetworkManager()))
}
