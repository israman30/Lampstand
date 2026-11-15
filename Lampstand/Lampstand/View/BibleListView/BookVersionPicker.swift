//
//  BookVersionPicker.swift
//  Lampstand
//
//  Created by Israel Manzo on 7/1/26.
//

import SwiftUI

struct BookVersionPicker: View {
    @State var viewModel: BibleBrowserViewModel
    var body: some View {
        Section {
            Picker("Book", selection: Binding(
                    get: { viewModel.selectedBookId },
                    set: { viewModel.userSelectedBook(id: $0) }
                )
            ) {
                ForEach(viewModel.availableBooks, id: \.id) { book in
                    Text(book.name)
                        .font(LampstandTheme.Typography.bodyEmphasis)
                        .foregroundStyle(LampstandTheme.Palette.ink)
                        .tag(book.id)
                }
            }
            .pickerStyle(.menu)
            .accessibilityHint("Choose a Bible book to read")
        } footer: {
            if let selected = viewModel.selectedBook {
                selectedBook(book: selected)
            }
        }
    }
    
    // MARK: - Selected Book
    private func selectedBook(book selected: BibleBook) -> some View {
        Text("\(selected.chapterCount) chapters")
            .font(LampstandTheme.Typography.caption)
            .foregroundStyle(LampstandTheme.Palette.inkSecondary)
            .accessibilityLabel("\(selected.chapterCount) chapters in \(selected.name)")
    }
}

#Preview {
    BookVersionPicker(viewModel: .init(networkManager: NetworkManager()))
}
