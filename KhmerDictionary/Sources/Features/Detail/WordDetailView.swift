import SwiftUI

struct WordDetailView: View {
    @EnvironmentObject private var session: AppSession

    let wordID: Int64

    @State private var word: WordDetail?
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            if let word {
                VStack(alignment: .leading, spacing: 16) {
                    Text(word.word)
                        .font(KhmerFont.bold(KhmerTypography.detailWordTitle))
                        .foregroundStyle(AppTheme.accent)

                    Button {
                        toggleBookmark()
                    } label: {
                        Label(word.isBookmarked ? "បានចំណាំ" : "ចំណាំ", systemImage: word.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(KhmerFont.regular(KhmerTypography.detailBookmarkLabel))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().stroke(Color.secondary.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Text(word.definition)
                        .font(KhmerFont.regular(KhmerTypography.detailDefinitionBody))
                        .foregroundStyle(Color(red: 0.15, green: 0.24, blue: 0.36))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            } else if let errorText {
                Text(errorText)
                    .font(KhmerFont.regular(18))
                    .foregroundStyle(.red)
                    .padding(20)
            } else {
                ProgressView()
                    .padding(20)
            }
        }
        .background(AppTheme.background)
        .navigationTitle("ពន្យល់ន័យ")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: wordID) {
            await loadWord()
        }
    }

    private func loadWord() async {
        do {
            let detail = try await session.repository.getWordByID(wordID)
            await MainActor.run {
                errorText = nil
                word = detail
            }
        } catch {
            await MainActor.run {
                errorText = error.localizedDescription
                word = nil
            }
        }
    }

    private func toggleBookmark() {
        guard let word else { return }

        Task {
            do {
                try await session.repository.setBookmark(wordID: word.id, isCurrentlyBookmarked: word.isBookmarked)
                await MainActor.run {
                    self.word?.isBookmarked.toggle()
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
