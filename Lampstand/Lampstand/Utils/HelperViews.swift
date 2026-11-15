//
//  HelperViews.swift
//  Lampstand
//
//  Created by Israel Manzo on 7/1/26.
//

import SwiftUI

struct ErrorResultView: View {
    var title: String
    var icon: String? = nil
    var message: String = ""
    
    init(with title: String, icon: String? = nil, message: String = "") {
        self.title = title
        self.icon = icon
        self.message = message
    }
    
    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: icon ?? "",
            description: Text(message)
        )
    }
}

struct LoadingResultView: View {
    var message: String
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(LampstandTheme.Typography.body)
                .foregroundStyle(LampstandTheme.Palette.inkSecondary)
        }
    }
}
