//
//  VerseSelectionView.swift
//  Lampstand
//
//  Created by Israel Manzo on 7/1/26.
//

import SwiftUI

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

#Preview {
    VerseSelectionView(viewModel: .init(networkManager: NetworkManager()))
}
