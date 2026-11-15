//
//  VerseResultView.swift
//  Lampstand
//
//  Created by Israel Manzo on 7/1/26.
//

import SwiftUI

struct VerseResultView: View {
    @ObservedObject var viewModel: BookViewModel
    var verse: Verse
    var body: some View {
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

#Preview {
    VerseResultView(
        viewModel: BookViewModel(networkManager: NetworkManager()),
        verse: Verse(
            book: "John",
            chapter: 1,
            verse: 1,
            text: "The chapter content goes here. Add some lines for testing the view"
        )
    )
}
