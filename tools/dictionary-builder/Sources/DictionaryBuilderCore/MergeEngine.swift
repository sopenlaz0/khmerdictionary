import Foundation

public enum MergeEngine {
    public static func merge(baseEntries: [ExistingDictionaryEntry], importCandidates: [ImportCandidate]) -> MergeResult {
        struct CandidateState {
            var entry: MergedDictionaryEntry
            var isFromImport: Bool
        }

        var states: [String: CandidateState] = [:]
        states.reserveCapacity(baseEntries.count + importCandidates.count)

        for base in baseEntries {
            let word = TextNormalization.normalizeWord(base.word)
            let definition = DefinitionSanitizer.sanitize(base.definition)
            guard !word.isEmpty, !definition.isEmpty else {
                continue
            }

            let key = TextNormalization.dedupeKey(forWord: word)
            states[key] = CandidateState(
                entry: MergedDictionaryEntry(
                    word: word,
                    definition: definition,
                    sourceID: "bundled",
                    license: "bundled",
                    attribution: "Bundled dictionary",
                    sourceURL: nil,
                    priority: 0
                ),
                isFromImport: false
            )
        }

        var inserted = 0
        var updated = 0
        var skipped = 0

        for candidate in importCandidates {
            let word = TextNormalization.normalizeWord(candidate.word)
            let definition = DefinitionSanitizer.sanitize(candidate.definition)

            guard !word.isEmpty, !definition.isEmpty else {
                skipped += 1
                continue
            }

            let normalizedDefinition = TextNormalization.normalizeDefinition(definition)
            guard !normalizedDefinition.isEmpty else {
                skipped += 1
                continue
            }

            let incoming = MergedDictionaryEntry(
                word: word,
                definition: normalizedDefinition,
                sourceID: candidate.sourceID,
                license: candidate.license,
                attribution: candidate.attribution,
                sourceURL: candidate.sourceURL,
                priority: candidate.priority
            )

            let key = TextNormalization.dedupeKey(forWord: word)
            if let existing = states[key] {
                if shouldReplace(existing: existing.entry, with: incoming) {
                    states[key] = CandidateState(entry: incoming, isFromImport: true)
                    if existing.isFromImport {
                        // Replacement among imports does not change insert/update counts.
                    } else {
                        updated += 1
                    }
                } else {
                    skipped += 1
                }
            } else {
                states[key] = CandidateState(entry: incoming, isFromImport: true)
                inserted += 1
            }
        }

        let sorted = states.values.map(\.entry).sorted {
            $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending
        }

        return MergeResult(entries: sorted, inserted: inserted, updated: updated, skipped: skipped)
    }

    private static func shouldReplace(existing: MergedDictionaryEntry, with incoming: MergedDictionaryEntry) -> Bool {
        if incoming.priority != existing.priority {
            return incoming.priority > existing.priority
        }

        if incoming.definition.count != existing.definition.count {
            return incoming.definition.count > existing.definition.count
        }

        if incoming.word.count != existing.word.count {
            return incoming.word.count > existing.word.count
        }

        return false
    }
}
