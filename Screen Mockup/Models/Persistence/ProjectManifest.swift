@preconcurrency import Foundation
@preconcurrency import CoreGraphics

struct ProjectManifest: Codable, Equatable, Sendable {
    var projectID: UUID
    var schemaVersion: Int
    var creationDate: Date
    var modifiedDate: Date
    
    // Document State
    var background: ManifestBackground
    var backgroundOpacity: Double
    
    var canvasRatio: String
    var canvasOrientation: String
    
    // Elements
    var elements: [ManifestElement]
    
    // Asset descriptors
    var assets: [AssetDescriptor]
    
    func allReferencedAssetIDs() -> Set<UUID> {
        var ids = Set<UUID>()
        if case .image(let ref) = background {
            ids.insert(ref.assetID)
        }
        for element in elements {
            switch element.content {
            case .image(let ref):
                ids.insert(ref.assetID)
            case .device(let data):
                ids.insert(data.media.assetID)
            default:
                break
            }
        }
        return ids
    }
}

enum ManifestBackground: Codable, Equatable, Sendable {
    case none
    case solid(ColorRGBA)
    case gradient(start: ColorRGBA, end: ColorRGBA)
    case image(MediaReference)
}

struct ManifestElementTransform: Codable, Equatable, Sendable {
    var normalizedPosition: [Double]
    var scale: Double
    var rotationDegrees: Double
    var opacity: Double
}

struct ManifestElement: Codable, Equatable, Sendable {
    var id: UUID
    var content: ManifestElementContent
    var transform: ManifestElementTransform
    var zIndex: Int
    var isLocked: Bool
    var isHidden: Bool
}

struct ManifestDeviceElementData: Codable, Equatable, Sendable {
    var media: MediaReference
    var bezelStyle: String
    var showStatusBar: Bool
}

enum ManifestElementContent: Codable, Equatable, Sendable {
    case device(ManifestDeviceElementData)
    case image(MediaReference)
    case text(ManifestTextData)
    case sfSymbol
}

struct ManifestTextData: Codable, Equatable, Sendable {
    var string: String
    var fontName: String
    var color: ColorRGBA
}

struct ColorRGBA: Codable, Equatable, Sendable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double
}

