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
                Image(systemName: "chevron.left")
                    .font(.system(.body, weight: .semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .background(Circle().fill(LampstandTheme.Palette.surface))
            .overlay(Circle().stroke(LampstandTheme.Palette.stroke, lineWidth: 1))
            .disabled(viewModel.selectedChapter <= viewModel.chapterRange.lowerBound)
            .accessibilityLabel("Previous chapter")
            .accessibilityHint(
                viewModel.selectedChapter > viewModel.chapterRange.lowerBound
                    ? "Go to chapter \(viewModel.selectedChapter - 1)"
                    : "Already at the first chapter"
            )

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.selectedBook?.name ?? "Lampstand")
                    .font(LampstandTheme.Typography.caption)
                    .foregroundStyle(LampstandTheme.Palette.inkSecondary)

                Text("Chapter \(viewModel.selectedChapter)")
                    .font(LampstandTheme.Typography.title)
                    .foregroundStyle(LampstandTheme.Palette.ink)
            }
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(
                "Chapter \(viewModel.selectedChapter) of \(viewModel.selectedBook?.name ?? "")"
            )

            Spacer()

            Button {
                next()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(.body, weight: .semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .background(Circle().fill(LampstandTheme.Palette.surface))
            .overlay(Circle().stroke(LampstandTheme.Palette.stroke, lineWidth: 1))
            .disabled(viewModel.selectedChapter >= viewModel.chapterRange.upperBound)
            .accessibilityLabel("Next chapter")
            .accessibilityHint(
                viewModel.selectedChapter < viewModel.chapterRange.upperBound
                    ? "Go to chapter \(viewModel.selectedChapter + 1)"
                    : "Already at the last chapter"
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LampstandTheme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LampstandTheme.Palette.stroke, lineWidth: 1)
        )
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
