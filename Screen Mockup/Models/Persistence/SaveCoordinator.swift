import Foundation

actor SaveCoordinator {
    private let store: ProjectStore
    private let assetStore: ProjectAssetStore
    
    private var latestSnapshot: ProjectManifest?
    private var latestRevision: Int = 0
    private var lastSavedRevision: Int = 0
    
    private var pendingTask: Task<Void, Never>?
    private var isSaving: Bool = false
    
    let debounceInterval: TimeInterval
    
    init(store: ProjectStore, assetStore: ProjectAssetStore, debounceInterval: TimeInterval = 1.0) {
        self.store = store
        self.assetStore = assetStore
        self.debounceInterval = debounceInterval
    }
    
    func schedule(_ snapshot: ProjectManifest) {
        latestRevision += 1
        latestSnapshot = snapshot
        
        let revisionToSave = latestRevision
        
        pendingTask?.cancel()
        pendingTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            if !Task.isCancelled {
                await performSave(for: revisionToSave)
            }
        }
    }
    
    func flushPending() async {
        pendingTask?.cancel()
        if latestRevision > lastSavedRevision {
            await performSave(for: latestRevision)
        }
    }
    
    private func performSave(for revision: Int) async {
        guard !isSaving else {
            // If currently saving, the scheduled task will naturally fall through, 
            // but we might miss it if a flush comes in.
            // A more robust queue could be used, but since schedule/flush cancels previous tasks,
            // we just need to ensure that the latest revision gets saved eventually.
            // If isSaving is true, we can just return, and schedule another immediate task
            // so it runs after the current save.
            Task {
                await performSave(for: revision)
            }
            return
        }
        
        // Don't save older revisions
        guard revision > lastSavedRevision else { return }
        guard let snapshot = latestSnapshot else { return }
        
        isSaving = true
        
        do {
            try await store.saveManifest(snapshot, assetStore: assetStore)
            lastSavedRevision = revision
        } catch {
            print("Failed to save manifest revision \(revision): \(error)")
            // On failure, we don't update lastSavedRevision so it can be retried
        }
        
        isSaving = false
    }
}
