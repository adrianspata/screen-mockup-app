import Foundation

actor ProjectStore {
    let projectID: UUID
    let directoryURL: URL
    let manifestURL: URL
    let assetsURL: URL
    
    init(projectID: UUID) throws {
        self.projectID = projectID
        let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        self.directoryURL = appSupport.appendingPathComponent("Projects").appendingPathComponent("\(projectID.uuidString).screenmockup")
        self.manifestURL = directoryURL.appendingPathComponent("manifest.json")
        self.assetsURL = directoryURL.appendingPathComponent("Assets")
    }
    
    func createProjectFoldersIfNeeded() throws {
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        if !FileManager.default.fileExists(atPath: assetsURL.path) {
            try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    struct SchemaCheck: Decodable {
        var schemaVersion: Int
    }
    
    struct ProjectManifestV1: Decodable {
        var projectID: UUID
        var schemaVersion: Int
        var creationDate: Date
        var modifiedDate: Date
        var media: MediaReference?
        var background: ManifestBackground
        var backgroundOpacity: Double
        var bezelStyle: String
        var showStatusBar: Bool
        var canvasRatio: String
        var canvasOrientation: String
        var scale: Double
        var normalizedOffset: [Double]
        var elements: [ManifestElementV1]
        var assets: [AssetDescriptor]
    }
    
    struct ManifestElementV1: Decodable {
        var id: UUID
        var content: ManifestElementContentV1
        var normalizedPosition: [Double]
        var scale: Double
        var zIndex: Int
    }
    
    enum ManifestElementContentV1: Decodable {
        case image(MediaReference)
        case text(ManifestTextData)
        case sfSymbol
        
        // Decodable implementation for the enum
        enum CodingKeys: String, CodingKey {
            case image, text, sfSymbol
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let ref = try? container.decode(MediaReference.self, forKey: .image) {
                self = .image(ref)
            } else if let text = try? container.decode(ManifestTextData.self, forKey: .text) {
                self = .text(text)
            } else if try container.decodeNil(forKey: .sfSymbol) {
                self = .sfSymbol
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid V1 content"))
            }
        }
    }
    
    func loadManifest() throws -> ProjectManifest {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw LoadError.missingManifest
        }
        
        let data = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        
        do {
            let check = try decoder.decode(SchemaCheck.self, from: data)
            
            if check.schemaVersion > 2 {
                throw LoadError.unsupportedSchemaVersion(check.schemaVersion)
            }
            
            let manifest: ProjectManifest
            
            if check.schemaVersion == 1 {
                let v1 = try decoder.decode(ProjectManifestV1.self, from: data)
                manifest = migrate(v1: v1)
            } else {
                manifest = try decoder.decode(ProjectManifest.self, from: data)
            }
            
            // Enum validation
            if CanvasRatio(rawValue: manifest.canvasRatio) == nil {
                throw LoadError.unsupportedCanvasRatio(manifest.canvasRatio)
            }
            if CanvasOrientation(rawValue: manifest.canvasOrientation) == nil {
                throw LoadError.unsupportedCanvasOrientation(manifest.canvasOrientation)
            }
            
            // Numeric validation
            if manifest.backgroundOpacity < 0 || manifest.backgroundOpacity > 1 || manifest.backgroundOpacity.isNaN {
                throw LoadError.invalidNumericValue("Background opacity must be between 0 and 1")
            }
            
            return manifest
        } catch let error as LoadError {
            throw error
        } catch {
            throw LoadError.corruptManifest(error)
        }
    }
    
    private func migrate(v1: ProjectManifestV1) -> ProjectManifest {
        var v2Elements: [ManifestElement] = []
        
        // 1. Map old elements to new
        for oldEl in v1.elements {
            let newContent: ManifestElementContent
            switch oldEl.content {
            case .image(let ref): newContent = .image(ref)
            case .text(let t): newContent = .text(t)
            case .sfSymbol: newContent = .sfSymbol
            }
            
            v2Elements.append(ManifestElement(
                id: oldEl.id,
                content: newContent,
                transform: ManifestElementTransform(
                    normalizedPosition: oldEl.normalizedPosition,
                    scale: oldEl.scale,
                    rotationDegrees: 0.0,
                    opacity: 1.0
                ),
                zIndex: oldEl.zIndex, // keep original zIndex for now
                isLocked: false,
                isHidden: false
            ))
        }
        
        // 2. Map global device to a new element if media exists
        if let media = v1.media {
            let oldOffset = CGSize(width: v1.normalizedOffset.count == 2 ? v1.normalizedOffset[0] : 0,
                                   height: v1.normalizedOffset.count == 2 ? v1.normalizedOffset[1] : 0)
            let deviceTransform = ManifestElementTransform(
                normalizedPosition: [Double(0.5 + oldOffset.width), Double(0.5 + oldOffset.height)],
                scale: v1.scale,
                rotationDegrees: 0.0,
                opacity: 1.0
            )
            let deviceData = ManifestDeviceElementData(
                media: media,
                bezelStyle: v1.bezelStyle,
                showStatusBar: v1.showStatusBar
            )
            v2Elements.append(ManifestElement(
                id: UUID(),
                content: .device(deviceData),
                transform: deviceTransform,
                zIndex: -1, // Intentionally lowest to be normalized later
                isLocked: false,
                isHidden: false
            ))
        }
        
        // 3. Normalize Z-Indices
        v2Elements.sort { $0.zIndex < $1.zIndex }
        for i in 0..<v2Elements.count {
            v2Elements[i].zIndex = i
        }
        
        return ProjectManifest(
            projectID: v1.projectID,
            schemaVersion: 2,
            creationDate: v1.creationDate,
            modifiedDate: v1.modifiedDate,
            background: v1.background,
            backgroundOpacity: v1.backgroundOpacity,
            canvasRatio: v1.canvasRatio,
            canvasOrientation: v1.canvasOrientation,
            elements: v2Elements,
            assets: v1.assets
        )
    }
    
    func saveManifest(_ manifest: ProjectManifest, assetStore: ProjectAssetStore) async throws {
        try createProjectFoldersIfNeeded()
        
        // Ensure all referenced IDs have descriptors
        let referencedIDs = manifest.allReferencedAssetIDs()
        for id in referencedIDs {
            let desc = await assetStore.getDescriptor(for: id)
            if desc == nil {
                throw LoadError.invalidNumericValue("Missing descriptor for referenced asset: \(id)")
            }
        }
        
        // Validate descriptors internal logic
        try await assetStore.validateDescriptors(manifest.assets)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(manifest)
        
        try data.write(to: manifestURL, options: .atomic)
        
        // Mark committed
        await assetStore.markCommitted(assetIDs: referencedIDs)
        
        // Garbage Collection
        let unusedFiles = try await assetStore.getUnusedFiles(in: assetsURL)
        for url in unusedFiles {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
