import SwiftUI

private struct BookmarkRoute: Hashable, Identifiable {
    let id: Int64
}

struct BookmarksView: View {
    @EnvironmentObject private var session: AppSession

    @State private var rows: [WordSummary] = []
    @State private var errorText: String?
    @State private var selectedWord: BookmarkRoute?

    var body: some View {
        List {
            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .listRowBackground(Color.clear)
            }

            if rows.isEmpty {
                Text("មិនទាន់មានពាក្យចំណាំ")
                    .font(KhmerFont.regular(20))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }

            ForEach(rows) { item in
                WordCardView(
                    word: item,
                    onOpen: { openWord(item) },
                    onToggleBookmark: { toggleBookmark(for: item) }
                )
                .swipeActions {
                    Button(role: .destructive) {
                        toggleBookmark(for: item)
                    } label: {
                        Label("លុបចំណាំ", systemImage: "bookmark.slash")
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("ចំណាំ")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: session.refreshVersion) {
            await reload()
        }
        .refreshable {
            await reload()
        }
        .navigationDestination(item: $selectedWord) { route in
            WordDetailView(wordID: route.id)
        }
    }

    @MainActor
    private func reload() async {
        do {
            errorText = nil
            rows = try await session.repository.listBookmarks(limit: 200)
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func openWord(_ word: WordSummary) {
        Task {
            try? await session.repository.addToHistory(wordID: word.id)
            await MainActor.run {
                selectedWord = BookmarkRoute(id: word.id)
                session.bumpRefresh()
            }
        }
    }

    private func toggleBookmark(for word: WordSummary) {
        Task {
            do {
                try await session.repository.setBookmark(wordID: word.id, isCurrentlyBookmarked: word.isBookmarked)
                await reload()
                await MainActor.run {
                    session.bumpRefresh()
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                }
            }
        }
    }
}
