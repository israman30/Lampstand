//
//  VerseRow.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/22/26.
//

import SwiftUI

struct VerseRow: View {
    let bookName: String?
    let chapter: Int
    let verseNumber: Int
    let text: String
    let isHighlighted: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(verseNumber)")
                .font(LampstandTheme.Typography.verseNumber)
                .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(LampstandTheme.Palette.stroke.opacity(0.9)))
                .accessibilityHidden(true)

            Text(text)
                .font(LampstandTheme.Typography.body)
                .foregroundStyle(LampstandTheme.Palette.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .lampstandCard(isHighlighted: isHighlighted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            LampstandAccessibility.verseLabel(
                book: bookName,
                chapter: chapter,
                verse: verseNumber,
                text: text,
                isHighlighted: isHighlighted
            )
        )
        .accessibilityAddTraits(isHighlighted ? [.isSelected] : [])
    }
}

#Preview {
    VerseRow(
        bookName: "Genesis",
        chapter: 1,
        verseNumber: 1,
        text: "In the beginning God created the heavens and the earth",
        isHighlighted: true
    )
}
