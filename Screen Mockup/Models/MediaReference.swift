@preconcurrency import Foundation
@preconcurrency import CoreGraphics

enum MediaKind: String, Codable, Equatable, Sendable {
    case image
    case video
}

struct MediaReference: Equatable, Codable, Sendable {
    let assetID: UUID
    let kind: MediaKind
    let pixelSize: CGSize? // Natural size of original media
    let duration: Double? // For video
    var cornerRadius: CGFloat = 0 // Used by CanvasElement
}

struct AssetDescriptor: Equatable, Codable, Sendable {
    let assetID: UUID
    let relativePath: String
    let contentType: String
    let byteCount: Int64?
}
