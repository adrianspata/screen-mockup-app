import SwiftUI
import Observation

enum SessionState {
    case loading
    case ready
    case error(LoadError)
}

@MainActor
@Observable
final class ProjectSession {
    var document: MockupDocument
    let store: ProjectStore
    let assetStore: ProjectAssetStore
    let saveCoordinator: SaveCoordinator
    
    private var observationTask: Task<Void, Never>?
    
    var state: SessionState = .loading
    
    init(projectID: UUID, document: MockupDocument? = nil) throws {
        self.document = document ?? MockupDocument()
        self.store = try ProjectStore(projectID: projectID)
        self.assetStore = ProjectAssetStore(projectID: projectID, directoryURL: self.store.assetsURL)
        self.saveCoordinator = SaveCoordinator(store: self.store, assetStore: self.assetStore)
    }
    
    func scheduleAutosave(snapshot: ProjectManifest) {
        Task {
            await saveCoordinator.schedule(snapshot)
        }
    }
    
    func startObservation() {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = self.document.persistenceSnapshot(projectID: self.store.projectID)
                    } onChange: {
                        continuation.resume()
                    }
                }
                
                let snapshot = self.document.persistenceSnapshot(projectID: self.store.projectID)
                self.scheduleAutosave(snapshot: snapshot)
            }
        }
    }
    
    
    func load() async {
        do {
            state = .loading
            let manifest = try await store.loadManifest()
            
            // Reconstruct document
            document.apply(manifest: manifest)
            
            // Asset store sets committed assets
            await assetStore.setCommittedAssets(manifest.assets)
            
            // Preload images
            var imageIDs = Set<UUID>()
            for element in manifest.elements {
                if case .image(let ref) = element.content {
                    imageIDs.insert(ref.assetID)
                } else if case .device(let data) = element.content, data.media.kind == .image {
                    imageIDs.insert(data.media.assetID)
                }
            }
            if case .image(let ref) = manifest.background {
                imageIDs.insert(ref.assetID)
            }
            try await assetStore.ensureImagesLoaded(for: imageIDs)
            
            state = .ready
            startObservation()
        } catch let error as LoadError {
            state = .error(error)
        } catch {
            state = .error(.corruptManifest(error))
        }
    }
    
    static func createNew() throws -> ProjectSession {
        let id = UUID()
        let session = try ProjectSession(projectID: id)
        
        let manifest = session.document.persistenceSnapshot(projectID: id)
        session.state = .ready
        session.startObservation()
        
        Task {
            try await session.store.createProjectFoldersIfNeeded()
            try await session.store.saveManifest(manifest, assetStore: session.assetStore)
            UserDefaults.standard.set(id.uuidString, forKey: "latestProjectID")
        }
        
        return session
    }
}
