import SwiftUI

private struct WordRoute: Hashable, Identifiable {
    let id: Int64
}

struct DictionaryView: View {
    @EnvironmentObject private var session: AppSession

    @State private var query = ""
    @State private var rows: [WordSummary] = []
    @State private var errorText: String?
    @State private var selectedWord: WordRoute?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("វចនានុក្រមខ្មែរ")
                        .font(KhmerFont.display(KhmerTypography.dictionaryHeroTitle))
                        .foregroundStyle(AppTheme.accent)
                    Text("ស្វែងរកដោយពាក្យដើម")
                        .font(KhmerFont.regular(KhmerTypography.dictionaryHeroSubtitle))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                .listRowBackground(Color.clear)
            }

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .listRowBackground(Color.clear)
            }

            if rows.isEmpty {
                VStack(spacing: 8) {
                    Text("មិនមានលទ្ធផល")
                        .font(KhmerFont.bold(KhmerTypography.emptyStateTitle))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("សូមសាកល្បងស្វែងរកដោយពាក្យខ្លី ឬការបញ្ចូលខុសគ្នាបន្តិច។")
                        .font(KhmerFont.regular(KhmerTypography.emptyStateBody))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .listRowBackground(Color.clear)
            }

            ForEach(rows) { item in
                WordCardView(
                    word: item,
                    onOpen: { openWord(item) },
                    onToggleBookmark: { toggleBookmark(for: item) }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [Color(red: 0.91, green: 0.95, blue: 1.0), AppTheme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("វចនានុក្រម")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .dictionarySearch(text: $query)
        .refreshable {
            await loadRows()
        }
        .onChange(of: query) { _, _ in
            scheduleSearch()
        }
        .task {
            await loadRows()
        }
        .navigationDestination(item: $selectedWord) { route in
            WordDetailView(wordID: route.id)
        }
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            await loadRows()
        }
    }

    @MainActor
    private func loadRows() async {
        do {
            errorText = nil
            rows = try await session.repository.searchWords(rawSearchTerm: query, limit: 90)
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func openWord(_ word: WordSummary) {
        Task {
            try? await session.repository.addToHistory(wordID: word.id)
            await MainActor.run {
                selectedWord = WordRoute(id: word.id)
                session.bumpRefresh()
            }
        }
    }

    private func toggleBookmark(for word: WordSummary) {
        Task {
            do {
                try await session.repository.setBookmark(wordID: word.id, isCurrentlyBookmarked: word.isBookmarked)
                await MainActor.run {
                    rows = rows.map { row in
                        if row.id == word.id {
                            var updated = row
                            updated.isBookmarked.toggle()
                            return updated
                        }
                        return row
                    }
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

private extension View {
    @ViewBuilder
    func dictionarySearch(text: Binding<String>) -> some View {
        if DictionarySearchPlacementPolicy.prefersNavigationBarDrawerAlways {
            searchable(
                text: text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("ស្វែងរកពាក្យ")
            )
                .dictionarySearchToolbarBehavior()
        } else if DictionarySearchPlacementPolicy.usesAdaptiveSystemPlacement {
            searchable(text: text, prompt: Text("ស្វែងរកពាក្យ"))
                .dictionarySearchToolbarBehavior()
        } else {
            searchable(
                text: text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("ស្វែងរកពាក្យ")
            )
            .dictionarySearchToolbarBehavior()
        }
    }

    @ViewBuilder
    func dictionarySearchToolbarBehavior() -> some View {
        if DictionarySearchPlacementPolicy.usesBottomMinimizedSearchToolbar {
            searchToolbarBehavior(.minimize)
        } else {
            self
        }
    }
}
