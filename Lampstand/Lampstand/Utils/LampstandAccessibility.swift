//
//  LampstandAccessibility.swift
//  Lampstand
//

import SwiftUI
import UIKit

enum LampstandAccessibility {
    static func spokenVersion(_ code: String) -> String {
        switch code {
        case "en-asv": "American Standard Version"
        case "en-kjv": "King James Version"
        default: code.uppercased()
        }
    }

    static func verseReference(book: String, chapter: Int, verse: Int) -> String {
        "\(book) \(chapter):\(verse)"
    }

    static func verseLabel(
        book: String? = nil,
        chapter: Int? = nil,
        verse: Int,
        text: String,
        isHighlighted: Bool = false
    ) -> String {
        let reference: String
        if let book, let chapter {
            reference = verseReference(book: book, chapter: chapter, verse: verse)
        } else {
            reference = "Verse \(verse)"
        }

        var label = "\(reference). \(text)"
        if isHighlighted {
            label += " Highlighted."
        }
        return label
    }

    static func announce(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

extension View {
    func lampstandDecorativeImage() -> some View {
        accessibilityHidden(true)
    }

    func lampstandSettingsMenuLabel() -> some View {
        accessibilityLabel("Settings")
            .accessibilityHint("Choose Bible translation or appearance")
    }

    func lampstandLoadingStatus(_ message: String, isLoading: Bool) -> some View {
        accessibilityElement(children: .combine)
            .accessibilityLabel(isLoading ? message : "")
            .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
}
