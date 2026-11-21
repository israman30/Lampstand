import SwiftUI

/// Presents locally saved verses and handles navigation and removal.
///
/// Selecting a row returns to the reader at the bookmarked reference. The list
/// supports both swipe deletion and the standard `List` delete interaction.
struct BookmarksView: View {
    @ObservedObject var store: BookmarkStore
    let onSelect: (BibleBookmark) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No bookmarks",
                        systemImage: "bookmark",
                        description: Text("Bookmark a verse to keep it close.")
                    )
                } else {
                    List {
                        ForEach(store.bookmarks) { bookmark in
                            Button {
                                onSelect(bookmark)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(bookmark.book) \(bookmark.chapter):\(bookmark.verse)")
                                        .font(LampstandTheme.Typography.bodyEmphasis)
                                        .foregroundStyle(LampstandTheme.Palette.ink)

                                    Text(bookmark.text)
                                        .font(LampstandTheme.Typography.reading)
                                        .foregroundStyle(LampstandTheme.Palette.inkSecondary)
                                        .lineLimit(3)

                                    Text(bookmark.version.uppercased())
                                        .font(LampstandTheme.Typography.caption)
                                        .foregroundStyle(LampstandTheme.Palette.accent)
                                }
                                .padding(.vertical, 6)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.remove(bookmark)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: store.remove)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .lampstandScreenBackground()
    }
}
