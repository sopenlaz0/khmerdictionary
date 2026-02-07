import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DictionaryView()
            }
            .tabItem {
                Label("វចនានុក្រម", systemImage: "book")
            }

            NavigationStack {
                BookmarksView()
            }
            .tabItem {
                Label("ចំណាំ", systemImage: "bookmark")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("ប្រវត្តិ", systemImage: "clock.arrow.circlepath")
            }
        }
        .tint(AppTheme.accent)
    }
}
