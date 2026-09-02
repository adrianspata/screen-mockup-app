import XCTest
@testable import Screen_Mockup

@MainActor
final class Sprint1_PersistenceTests: XCTestCase {
    var session: ProjectSession!
    var projectID: UUID!
    
    override func setUp() async throws {
        projectID = UUID()
        session = try ProjectSession(projectID: projectID)
        session.state = .ready
    }
    
    override func tearDown() async throws {
        _ = await session.store.directoryURL
        // if FileManager.default.fileExists(atPath: url.path) {
        //     try FileManager.default.removeItem(at: url)
        // }
    }
    
    func testAutosaveObservationTriggersSave() async throws {
        // Start central observation
        session.startObservation()
        
        // Yield to allow the observation Task to start and register tracking
        await Task.yield()
        
        // Mutate document
        session.document.canvasRatio = .twoToThree
        
        // Wait for debounce and save (SaveCoordinator debounce is 1.0, wait 1.5s)
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Verify manifest is written
        let manifest = try await session.store.loadManifest()
        XCTAssertEqual(manifest.canvasRatio, CanvasRatio.twoToThree.rawValue)
    }
    
    func testSaveCoordinatorDebounce() async throws {
        let projectID = await session.store.projectID
        let snapshot1 = session.document.persistenceSnapshot(projectID: projectID)
        
        // Mutate and schedule quickly
        session.document.canvasRatio = .threeToFour
        let snapshot2 = session.document.persistenceSnapshot(projectID: projectID)
        
        await session.saveCoordinator.schedule(snapshot1)
        await session.saveCoordinator.schedule(snapshot2)
        
        // The first save should be cancelled by the second one
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        let manifest = try await session.store.loadManifest()
        // It should have saved the latest snapshot
        XCTAssertEqual(manifest.canvasRatio, CanvasRatio.threeToFour.rawValue)
    }
    
    func testSaveCoordinatorFlush() async throws {
        let projectID = await session.store.projectID
        session.document.canvasRatio = .nineToSixteen
        let snapshot = session.document.persistenceSnapshot(projectID: projectID)
        
        await session.saveCoordinator.schedule(snapshot)
        
        // Instantly flush, bypassing debounce
        await session.saveCoordinator.flushPending()
        
        let manifest = try await session.store.loadManifest()
        XCTAssertEqual(manifest.canvasRatio, CanvasRatio.nineToSixteen.rawValue)
    }
    
    func testAssetGarbageCollection() async throws {
        let projectID = await session.store.projectID
        
        do {
            try await session.store.createProjectFoldersIfNeeded()
        } catch { XCTFail("Failed at createProjectFoldersIfNeeded: \(error)"); return }
        
        let testImage = UIImage(systemName: "star")!
        let data = testImage.jpegData(compressionQuality: 0.8)!
        
        let ref: MediaReference
        do {
            ref = try await session.assetStore.importImage(from: data, utType: "public.jpeg", fileExtension: "jpg")
        } catch { XCTFail("Failed at importImage: \(error)"); return }
        
        let url: URL
        do {
            url = try await session.assetStore.url(for: ref.assetID)
        } catch { XCTFail("Failed at url(for:): \(error)"); return }
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "File should exist after import")
        
        do {
            try await session.store.createProjectFoldersIfNeeded()
        } catch { XCTFail("Failed at createProjectFoldersIfNeeded 2: \(error)"); return }
        
        let unused1: [URL]
        do {
            unused1 = try await session.assetStore.getUnusedFiles(in: session.store.assetsURL)
        } catch { XCTFail("Failed at getUnusedFiles 1: \(error)"); return }
        XCTAssertFalse(unused1.contains(url), "File should not be unused when pending")
        
        let element = CanvasElement(content: .image(ref), zIndex: 0)
        session.document.elements = [element]
        let snapshot = session.document.persistenceSnapshot(projectID: projectID)
        
        do {
            try await session.store.saveManifest(snapshot, assetStore: session.assetStore)
        } catch { XCTFail("Failed at saveManifest 1: \(error)"); return }
        
        let unused2: [URL]
        do {
            unused2 = try await session.assetStore.getUnusedFiles(in: session.store.assetsURL)
        } catch { XCTFail("Failed at getUnusedFiles 2: \(error)"); return }
        XCTAssertFalse(unused2.contains(url), "File should not be unused when committed")
        
        session.document.elements = []
        let snapshot2 = session.document.persistenceSnapshot(projectID: projectID)
        do {
            try await session.store.saveManifest(snapshot2, assetStore: session.assetStore)
        } catch { XCTFail("Failed at saveManifest 2: \(error)"); return }
        
        let unused3: [URL]
        do {
            unused3 = try await session.assetStore.getUnusedFiles(in: session.store.assetsURL)
        } catch { XCTFail("Failed at getUnusedFiles 3: \(error)"); return }
        XCTAssertFalse(unused3.contains(url), "File should not be present in unused files because it was deleted")
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "File should be deleted by GC")
    }
}
