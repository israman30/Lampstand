//
//  LampstandApp.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
//

import SwiftUI

@main
struct LampstandApp: App {
    @AppStorage("lampstand.appearance") private var appearanceRawValue: String = LampstandAppearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(LampstandTheme.Palette.accent)
                .preferredColorScheme(LampstandAppearance(rawValue: appearanceRawValue)?.colorScheme)
        }
    }
}
