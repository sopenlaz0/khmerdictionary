import SwiftUI

private struct WordRoute: Hashable, Identifiable {
    let id: Int64
}

struct DictionaryView: View {
    @EnvironmentObject private var session: AppSession

    private let pageSize = 90

    @State private var query = ""
    @State private var rows: [WordSummary] = []
    @State private var errorText: String?
    @State private var selectedWord: WordRoute?
    @State private var searchTask: Task<Void, Never>?
    @State private var nextOffset = 0
    @State private var hasMoreRows = true
    @State private var isLoadingPage = false

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

            if rows.isEmpty, !isLoadingPage, errorText == nil {
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
                .onAppear {
                    loadMoreIfNeeded(currentWordID: item.id)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            if isLoadingPage, !rows.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [AppTheme.heroGradientStart, AppTheme.background],
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
            await reloadFromStart()
        }
        .onChange(of: query) { _, _ in
            scheduleSearch()
        }
        .task {
            await reloadFromStart()
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
            await reloadFromStart()
        }
    }

    @MainActor
    private func reloadFromStart() async {
        nextOffset = 0
        hasMoreRows = true
        rows = []
        await loadNextPage()
    }

    @MainActor
    private func loadNextPage() async {
        guard !isLoadingPage, hasMoreRows else { return }

        let requestedQuery = query
        let currentOffset = nextOffset
        isLoadingPage = true

        do {
            let page = try await session.repository.searchWords(
                rawSearchTerm: requestedQuery,
                limit: pageSize,
                offset: currentOffset
            )

            guard requestedQuery == query else {
                isLoadingPage = false
                return
            }

            errorText = nil
            rows.append(contentsOf: page)
            nextOffset += page.count
            hasMoreRows = page.count == pageSize
        } catch {
            guard requestedQuery == query else {
                isLoadingPage = false
                return
            }

            errorText = error.localizedDescription
            hasMoreRows = false
        }

        isLoadingPage = false
    }

    private func loadMoreIfNeeded(currentWordID: Int64) {
        guard !rows.isEmpty, hasMoreRows, !isLoadingPage else { return }
        guard rows.last?.id == currentWordID else { return }
        Task {
            await loadNextPage()
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
