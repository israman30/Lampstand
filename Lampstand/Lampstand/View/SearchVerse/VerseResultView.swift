//
//  VerseResultView.swift
//  Lampstand
//
//  Created by Israel Manzo on 7/1/26.
//

import SwiftUI

struct VerseResultView: View {
    @ObservedObject var viewModel: BookViewModel
    @ObservedObject var bookmarkStore: BookmarkStore
    var verse: Verse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                let bookName = verse.book ?? viewModel.bookText
                Text("\(bookName) \(verse.chapter):\(verse.verse)")
                    .font(.system(.headline, design: .default, weight: .semibold))
                    .foregroundStyle(LampstandTheme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                let isBookmarked = bookmarkStore.isBookmarked(
                    book: bookName,
                    chapter: verse.chapter,
                    verse: verse.verse,
                    version: viewModel.version
                )

                Button {
                    bookmarkStore.toggle(
                        BibleBookmark(
                            book: bookName,
                            chapter: verse.chapter,
                            verse: verse.verse,
                            text: verse.text,
                            version: viewModel.version
                        )
                    )
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(isBookmarked ? LampstandTheme.Palette.accent : LampstandTheme.Palette.inkSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(LampstandTheme.Palette.surface))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark verse")
            }

            Text(verse.text)
                .verseTextStyle(
                    font: LampstandTheme.Typography.reading,
                    color: LampstandTheme.Palette.ink,
                    spacing: 5
                )
                .textSelection(.enabled)
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
        bookmarkStore: BookmarkStore(),
        verse: Verse(
            book: "John",
            chapter: 1,
            verse: 1,
            text: "The chapter content goes here. Add some lines for testing the view"
        )
    )
}
