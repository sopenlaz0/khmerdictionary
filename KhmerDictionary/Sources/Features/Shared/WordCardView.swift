import SwiftUI

struct WordCardView: View {
    let word: WordSummary
    let onOpen: () -> Void
    let onToggleBookmark: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.word)
                        .font(KhmerFont.bold(KhmerTypography.listWordTitle))
                        .foregroundStyle(AppTheme.accent)
                        .lineLimit(1)

                    Text(word.previewDefinition)
                        .font(KhmerFont.regular(KhmerTypography.listPreviewBody))
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Button(action: onToggleBookmark) {
                    Image(systemName: word.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundStyle(word.isBookmarked ? AppTheme.accent : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(word.isBookmarked ? "Remove Bookmark" : "Add Bookmark")
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
    }
}
