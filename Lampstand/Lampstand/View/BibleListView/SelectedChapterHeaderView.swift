//
//  SelectedChapterHeaderView.swift
//  Lampstand
//
//  Created by Israel Manzo on 7/1/26.
//

import SwiftUI

// MARK: - Selected Chapter Header Section
struct SelectedChapterHeaderView: View {
    var viewModel: BibleBrowserViewModel
    var previous: () -> Void
    var next: () -> Void
    
    init(viewMode: BibleBrowserViewModel, previous: @escaping () -> Void, next: @escaping () -> Void) {
        self.viewModel = viewMode
        self.previous = previous
        self.next = next
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                previous()
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .imageScale(.medium)
            }
            .disabled(viewModel.selectedChapter <= viewModel.chapterRange.lowerBound)
            .accessibilityLabel("Previous chapter")
            .accessibilityHint(
                viewModel.selectedChapter > viewModel.chapterRange.lowerBound
                    ? "Go to chapter \(viewModel.selectedChapter - 1)"
                    : "Already at the first chapter"
            )

            Spacer()

            Text("Chapter \(viewModel.selectedChapter)")
                .font(LampstandTheme.Typography.title)
                .foregroundStyle(LampstandTheme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(
                    "Chapter \(viewModel.selectedChapter) of \(viewModel.selectedBook?.name ?? "")"
                )

            Spacer()

            Button {
                next()
            } label: {
                Label("Next", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .imageScale(.medium)
            }
            .disabled(viewModel.selectedChapter >= viewModel.chapterRange.upperBound)
            .accessibilityLabel("Next chapter")
            .accessibilityHint(
                viewModel.selectedChapter < viewModel.chapterRange.upperBound
                    ? "Go to chapter \(viewModel.selectedChapter + 1)"
                    : "Already at the last chapter"
            )
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    SelectedChapterHeaderView(
        viewMode: .init(networkManager: NetworkManager()),
        previous: {
            print("previous")
        },
        next: {
            print("next")
        })
}
