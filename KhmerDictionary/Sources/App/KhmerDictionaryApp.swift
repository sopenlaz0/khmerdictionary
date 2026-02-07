import SwiftUI

@MainActor
private final class AppLoader: ObservableObject {
    enum State {
        case loading
        case failed(String)
        case ready(AppSession)
    }

    @Published var state: State = .loading

    func load() {
        do {
            state = .ready(try AppSession.bootstrap())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

@main
struct KhmerDictionaryApp: App {
    @StateObject private var loader = AppLoader()

    var body: some Scene {
        WindowGroup {
            Group {
                switch loader.state {
                case .loading:
                    ProgressView("Loading Dictionary…")
                        .tint(AppTheme.accent)
                case let .failed(message):
                    VStack(spacing: 12) {
                        Text("Failed to initialize app")
                            .font(.headline)
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            loader.load()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                case let .ready(session):
                    RootTabView()
                        .environmentObject(session)
                        .background(AppTheme.background)
                }
            }
            .task {
                if case .loading = loader.state {
                    loader.load()
                }
            }
        }
    }
}
