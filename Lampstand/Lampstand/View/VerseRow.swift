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
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(isHighlighted ? LampstandTheme.Palette.accent : LampstandTheme.Palette.inkSecondary)
                .frame(minWidth: 24, alignment: .trailing)
                .accessibilityHidden(true)

            Text(text)
                .verseTextStyle(
                    font: LampstandTheme.Typography.reading,
                    color: LampstandTheme.Palette.ink,
                    spacing: 5
                )
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 7)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    isHighlighted
                        ? LampstandTheme.Palette.highlight
                        : LampstandTheme.Palette.surface.opacity(0.72)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LampstandTheme.Palette.stroke, lineWidth: 0.8)
        )
        .contentShape(Rectangle())
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

/// `Verse Text Style Modifier for VerseRow`
struct VerseTextStyleView: ViewModifier {
    var font: Font
    var color: Color
    var spacing: CGFloat = 2
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(spacing)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    func verseTextStyle(font: Font, color: Color, spacing: CGFloat = 2) -> some View {
        modifier(VerseTextStyleView(font: font, color: color, spacing: spacing))
    }
}
