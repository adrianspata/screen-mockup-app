import Foundation
import CoreGraphics

// A canonical representation of an object's bounds in normalized [0...1] canvas space.
struct SnapGeometry: Equatable {
    var minX: CGFloat
    var maxX: CGFloat
    var minY: CGFloat
    var maxY: CGFloat
    
    var centerX: CGFloat { (minX + maxX) / 2 }
    var centerY: CGFloat { (minY + maxY) / 2 }
    var width: CGFloat { maxX - minX }
    var height: CGFloat { maxY - minY }
    
    // Shift geometry by a normalized translation
    func translated(by translation: CGSize) -> SnapGeometry {
        SnapGeometry(
            minX: minX + translation.width,
            maxX: maxX + translation.width,
            minY: minY + translation.height,
            maxY: maxY + translation.height
        )
    }
}

enum SnapTargetPriority: Int, Comparable {
    case canvasCenter = 0
    case objectCenter = 1
    case canvasEdge = 2
    case safeMargin = 3
    case objectMatchingEdge = 4
    case objectAdjacentEdge = 5
    
    static func < (lhs: SnapTargetPriority, rhs: SnapTargetPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum SnapAnchor: Equatable {
    case min
    case max
}

enum SnapTargetType: Equatable {
    case canvasCenter
    case canvasEdge(SnapAnchor)
    case safeMargin(SnapAnchor)
    case objectCenter(UUID)
    case objectMatchingEdge(UUID, SnapAnchor)
    case objectAdjacentEdge(UUID, SnapAnchor)
    
    var priority: SnapTargetPriority {
        switch self {
        case .canvasCenter: return .canvasCenter
        case .canvasEdge: return .canvasEdge
        case .safeMargin: return .safeMargin
        case .objectCenter: return .objectCenter
        case .objectMatchingEdge: return .objectMatchingEdge
        case .objectAdjacentEdge: return .objectAdjacentEdge
        }
    }
    
    var objectID: UUID? {
        switch self {
        case .objectCenter(let id), .objectMatchingEdge(let id, _), .objectAdjacentEdge(let id, _): return id
        default: return nil
        }
    }
}

struct SnapResult: Equatable {
    // The corrected normalized offset to apply
    var correctedOffset: CGSize
    
    // Identifiers for the active guides (to show visually)
    // In normalized coordinates
    var activeVerticalGuide: CGFloat? 
    var activeHorizontalGuide: CGFloat?
    
    var snappedXType: SnapTargetType?
    var snappedYType: SnapTargetType?
}

final class SnapEngine {
    // Configuration
    // The threshold in normalized space. Since we want an absolute visual feel, 
    // we should compute this dynamically based on physical canvas width/height.
    // However, a good generic normalized default is roughly 2-3% of the canvas.
    // We will let the caller pass the threshold as a configuration.
    
    static func evaluateSnap(
        proposedGeometry: SnapGeometry,
        originalOffset: CGSize,
        proposedTranslation: CGSize,
        thresholdX: CGFloat,
        thresholdY: CGFloat,
        releaseThresholdX: CGFloat,
        releaseThresholdY: CGFloat,
        activeSnapX: SnapTargetType? = nil,
        activeSnapY: SnapTargetType? = nil,
        otherObjects: [UUID: SnapGeometry] = [:]
    ) -> SnapResult {
        
        let proposed = proposedGeometry.translated(by: proposedTranslation)
        
        struct Candidate {
            var distance: CGFloat
            var targetValue: CGFloat
            var type: SnapTargetType
            
            func isBetter(than other: Candidate?) -> Bool {
                guard let other = other else { return true }
                
                let absDist = abs(self.distance)
                let otherAbsDist = abs(other.distance)
                
                // 1. Smallest absolute distance
                // Use a small epsilon to avoid floating point inconsistencies
                if abs(absDist - otherAbsDist) > 1e-6 {
                    return absDist < otherAbsDist
                }
                
                // 2. Explicit SnapTarget priority
                if self.type.priority != other.type.priority {
                    return self.type.priority < other.type.priority
                }
                
                // 3. Stable object identity tie-break
                if let id1 = self.type.objectID, let id2 = other.type.objectID, id1 != id2 {
                    return id1.uuidString < id2.uuidString
                }
                
                // 4. Deterministic fallback
                return self.targetValue < other.targetValue
            }
        }
        
        var bestX: Candidate?
        var bestY: Candidate?
        
        // Helper to check horizontal targets (snapping X coordinates)
        func checkX(_ objectX: CGFloat, targetX: CGFloat, type: SnapTargetType) {
            let dx = targetX - objectX
            let isCurrentlyActive = (type == activeSnapX)
            let threshold = isCurrentlyActive ? releaseThresholdX : thresholdX
            
            if abs(dx) < threshold {
                let candidate = Candidate(distance: dx, targetValue: targetX, type: type)
                if candidate.isBetter(than: bestX) {
                    bestX = candidate
                }
            }
        }
        
        // Helper to check vertical targets (snapping Y coordinates)
        func checkY(_ objectY: CGFloat, targetY: CGFloat, type: SnapTargetType) {
            let dy = targetY - objectY
            let isCurrentlyActive = (type == activeSnapY)
            let threshold = isCurrentlyActive ? releaseThresholdY : thresholdY
            
            if abs(dy) < threshold {
                let candidate = Candidate(distance: dy, targetValue: targetY, type: type)
                if candidate.isBetter(than: bestY) {
                    bestY = candidate
                }
            }
        }
        
        // --- X AXIS TARGETS ---
        // Center
        checkX(proposed.centerX, targetX: 0.5, type: .canvasCenter)
        // Canvas Edges
        checkX(proposed.minX, targetX: 0.0, type: .canvasEdge(.min))
        checkX(proposed.maxX, targetX: 1.0, type: .canvasEdge(.max))
        // Safe Margins (5%)
        checkX(proposed.minX, targetX: 0.05, type: .safeMargin(.min))
        checkX(proposed.maxX, targetX: 0.95, type: .safeMargin(.max))
        
        // Other Objects
        for (id, otherGeom) in otherObjects {
            // center to center
            checkX(proposed.centerX, targetX: otherGeom.centerX, type: .objectCenter(id))
            // edge to edge (matching edges)
            checkX(proposed.minX, targetX: otherGeom.minX, type: .objectMatchingEdge(id, .min))
            checkX(proposed.maxX, targetX: otherGeom.maxX, type: .objectMatchingEdge(id, .max))
            // edge to edge (adjacent edges)
            checkX(proposed.minX, targetX: otherGeom.maxX, type: .objectAdjacentEdge(id, .max))
            checkX(proposed.maxX, targetX: otherGeom.minX, type: .objectAdjacentEdge(id, .min))
        }
        
        // --- Y AXIS TARGETS ---
        // Center
        checkY(proposed.centerY, targetY: 0.5, type: .canvasCenter)
        // Canvas Edges
        checkY(proposed.minY, targetY: 0.0, type: .canvasEdge(.min))
        checkY(proposed.maxY, targetY: 1.0, type: .canvasEdge(.max))
        // Safe Margins (5%)
        checkY(proposed.minY, targetY: 0.05, type: .safeMargin(.min))
        checkY(proposed.maxY, targetY: 0.95, type: .safeMargin(.max))
        
        // Other Objects
        for (id, otherGeom) in otherObjects {
            // center to center
            checkY(proposed.centerY, targetY: otherGeom.centerY, type: .objectCenter(id))
            // edge to edge (matching edges)
            checkY(proposed.minY, targetY: otherGeom.minY, type: .objectMatchingEdge(id, .min))
            checkY(proposed.maxY, targetY: otherGeom.maxY, type: .objectMatchingEdge(id, .max))
            // edge to edge (adjacent edges)
            checkY(proposed.minY, targetY: otherGeom.maxY, type: .objectAdjacentEdge(id, .max))
            checkY(proposed.maxY, targetY: otherGeom.minY, type: .objectAdjacentEdge(id, .min))
        }
        
        let finalTranslation = CGSize(
            width: proposedTranslation.width + (bestX?.distance ?? 0),
            height: proposedTranslation.height + (bestY?.distance ?? 0)
        )
        
        return SnapResult(
            correctedOffset: CGSize(
                width: originalOffset.width + finalTranslation.width,
                height: originalOffset.height + finalTranslation.height
            ),
            activeVerticalGuide: bestX?.targetValue,
            activeHorizontalGuide: bestY?.targetValue,
            snappedXType: bestX?.type,
            snappedYType: bestY?.type
        )
    }
}
