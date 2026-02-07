import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: AppSession

    @State private var isChecking = false
    @State private var statusMessage: String?
    @State private var currentVersionCode: Int?
    @State private var pendingVersionCode: Int?

    var body: some View {
        List {
            Section("Dictionary Updates") {
                LabeledContent("Current Version") {
                    Text(currentVersionCode.map(String.init) ?? "unknown")
                }

                LabeledContent("Pending Update") {
                    Text(pendingVersionCode.map(String.init) ?? "none")
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Button {
                    checkForUpdates()
                } label: {
                    Text(isChecking ? "កំពុងពិនិត្យ…" : "ពិនិត្យ និងទាញយក Update")
                }
                .disabled(isChecking)

                Text("Update នឹងត្រូវអនុវត្តនៅពេលបិទបើកកម្មវិធីឡើងវិញ បន្ទាប់ពី signature/hash verification ជោគជ័យ។")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let bootstrapError = session.bootstrapErrorMessage {
                Section("Startup Notice") {
                    Text(bootstrapError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("ការកំណត់")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshStatus()
        }
    }

    @MainActor
    private func refreshStatus() async {
        do {
            currentVersionCode = try await session.repository.currentDictionaryVersionCode()
            pendingVersionCode = session.updateService.pendingVersionCode()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func checkForUpdates() {
        Task {
            await MainActor.run {
                isChecking = true
                statusMessage = nil
            }

            let currentVersion: Int?
            do {
                currentVersion = try await session.repository.currentDictionaryVersionCode()
            } catch {
                await MainActor.run {
                    statusMessage = error.localizedDescription
                    isChecking = false
                }
                return
            }

            let result = await session.updateService.checkAndStageUpdate(currentVersionCode: currentVersion)
            await MainActor.run {
                switch result {
                case let .missingConfig(message):
                    statusMessage = message
                case .upToDate:
                    statusMessage = "ទិន្នន័យរបស់អ្នកគឺថ្មីបំផុតហើយ។"
                case let .staged(remoteVersionCode, _):
                    pendingVersionCode = remoteVersionCode
                    statusMessage = "បានទាញយក និងផ្ទៀងផ្ទាត់រួច។ សូមបិទបើកកម្មវិធីឡើងវិញដើម្បីអនុវត្ត update។"
                case let .error(message):
                    statusMessage = message
                }
                isChecking = false
            }

            await refreshStatus()
        }
    }
}
