import XCTest
@testable import Screen_Mockup

final class Phase81_SnapEngineTests: XCTestCase {

    func test1_NoSnapOutsideThreshold() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.2, maxY: 0.4) // Center is 0.3
        let result = SnapEngine.evaluateSnap(
            proposedGeometry: proposed,
            originalOffset: .zero,
            proposedTranslation: .zero,
            thresholdX: 0.01,
            thresholdY: 0.01,
            releaseThresholdX: 0.02,
            releaseThresholdY: 0.02
        )
        XCTAssertEqual(result.correctedOffset, .zero)
        XCTAssertNil(result.snappedXType)
        XCTAssertNil(result.snappedYType)
    }

    func test2_VerticalCenterSnap() {
        let proposed = SnapGeometry(minX: 0.395, maxX: 0.595, minY: 0.2, maxY: 0.4) // CenterX = 0.495
        let result = SnapEngine.evaluateSnap(
            proposedGeometry: proposed,
            originalOffset: .zero,
            proposedTranslation: .zero,
            thresholdX: 0.01,
            thresholdY: 0.01,
            releaseThresholdX: 0.02,
            releaseThresholdY: 0.02
        )
        XCTAssertEqual(result.correctedOffset.width, 0.005, accuracy: 0.0001)
        XCTAssertEqual(result.activeVerticalGuide, 0.5)
        XCTAssertEqual(result.snappedXType, .canvasCenter)
    }

    func test3_HorizontalCenterSnap() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.408, maxY: 0.608) // CenterY = 0.508
        let result = SnapEngine.evaluateSnap(
            proposedGeometry: proposed,
            originalOffset: .zero,
            proposedTranslation: .zero,
            thresholdX: 0.01,
            thresholdY: 0.01,
            releaseThresholdX: 0.02,
            releaseThresholdY: 0.02
        )
        XCTAssertEqual(result.correctedOffset.height, -0.008, accuracy: 0.0001)
        XCTAssertEqual(result.activeHorizontalGuide, 0.5)
        XCTAssertEqual(result.snappedYType, .canvasCenter)
    }

    func test4_SimultaneousXYCenterSnap() {
        let proposed = SnapGeometry(minX: 0.395, maxX: 0.595, minY: 0.408, maxY: 0.608)
        let result = SnapEngine.evaluateSnap(
            proposedGeometry: proposed,
            originalOffset: .zero,
            proposedTranslation: .zero,
            thresholdX: 0.01,
            thresholdY: 0.01,
            releaseThresholdX: 0.02,
            releaseThresholdY: 0.02
        )
        XCTAssertEqual(result.activeVerticalGuide, 0.5)
        XCTAssertEqual(result.activeHorizontalGuide, 0.5)
    }
    
    // CANVAS EDGES
    func test5_LeftEdgeSnap() {
        let proposed = SnapGeometry(minX: 0.005, maxX: 0.2, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.correctedOffset.width, -0.005, accuracy: 0.0001)
        XCTAssertEqual(result.snappedXType, .canvasEdge(.min))
        XCTAssertEqual(result.activeVerticalGuide, 0.0)
    }
    func test6_RightEdgeSnap() {
        let proposed = SnapGeometry(minX: 0.8, maxX: 0.992, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.correctedOffset.width, 0.008, accuracy: 0.0001)
        XCTAssertEqual(result.snappedXType, .canvasEdge(.max))
        XCTAssertEqual(result.activeVerticalGuide, 1.0)
    }
    func test7_TopEdgeSnap() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: -0.007, maxY: 0.193)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.correctedOffset.height, 0.007, accuracy: 0.0001)
        XCTAssertEqual(result.snappedYType, .canvasEdge(.min))
        XCTAssertEqual(result.activeHorizontalGuide, 0.0)
    }
    func test8_BottomEdgeSnap() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.8, maxY: 1.006)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.correctedOffset.height, -0.006, accuracy: 0.0001)
        XCTAssertEqual(result.snappedYType, .canvasEdge(.max))
        XCTAssertEqual(result.activeHorizontalGuide, 1.0)
    }

    // SAFE MARGINS
    func test9_Left5Percent() {
        let proposed = SnapGeometry(minX: 0.054, maxX: 0.254, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeVerticalGuide, 0.05)
        XCTAssertEqual(result.snappedXType, .safeMargin(.min))
    }
    func test10_Right5Percent() {
        let proposed = SnapGeometry(minX: 0.746, maxX: 0.946, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeVerticalGuide, 0.95)
        XCTAssertEqual(result.snappedXType, .safeMargin(.max))
    }
    func test11_Top5Percent() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.058, maxY: 0.258)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeHorizontalGuide, 0.05)
        XCTAssertEqual(result.snappedYType, .safeMargin(.min))
    }
    func test12_Bottom5Percent() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.742, maxY: 0.942)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeHorizontalGuide, 0.95)
        XCTAssertEqual(result.snappedYType, .safeMargin(.max))
    }
    
    // BOUNDING GEOMETRY
    func test13_LeftObjectEdgeToLeftSafeMargin() {
        // Confirms it's matching minX, not center
        let proposed = SnapGeometry(minX: 0.052, maxX: 0.5, minY: 0.2, maxY: 0.4) // Center is ~0.27
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeVerticalGuide, 0.05)
    }
    func test14_RightObjectEdgeToRightSafeMargin() {
        let proposed = SnapGeometry(minX: 0.1, maxX: 0.948, minY: 0.2, maxY: 0.4) // Center is ~0.52
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeVerticalGuide, 0.95)
    }
    func test15_TopObjectEdgeToTopSafeMargin() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.048, maxY: 0.8)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeHorizontalGuide, 0.05)
    }
    func test16_BottomObjectEdgeToBottomSafeMargin() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.1, maxY: 0.953)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeHorizontalGuide, 0.95)
    }
    
    func test17_CenterCalculationRespectsObjectWidth() {
        // If object is very wide (width 0.8), center is at 0.495
        let proposed = SnapGeometry(minX: 0.095, maxX: 0.895, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeVerticalGuide, 0.5) // Center snaps
    }
    
    func test18_CenterCalculationRespectsObjectHeight() {
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.095, maxY: 0.895)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeHorizontalGuide, 0.5)
    }
    
    // DETERMINISM
    func test19_ClosestCandidateWins() {
        // minX is 0.002 from edge (0.0). Center is 0.008 from center (0.5).
        let proposed = SnapGeometry(minX: 0.002, maxX: 0.982, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeVerticalGuide, 0.0) // 0.002 wins
    }
    
    func test20_DeterministicTieBreak() {
        // minX is 0.005 from edge (0.0), Center is 0.005 from center (0.5)
        // Mathematically impossible if width is not exact, let's make it exact.
        // minX = 0.005 -> Center = 0.505 -> dx = -0.005. Both dx are equal.
        let proposed = SnapGeometry(minX: 0.005, maxX: 1.005, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        // With current implementation, the FIRST one checked in SnapEngine code will win because we check `abs(dx) < abs(currentBest)`
        // Center is checked first, so Center should be currentBest. Edge is checked next, 0.005 is NOT strictly less than 0.005, so Center should remain.
        XCTAssertEqual(result.activeVerticalGuide, 0.5)
    }
    
    // HYSTERESIS
    // Since hysteresis is managed by the caller passing a larger threshold, we test that explicitly.
    func test21_SnapEntersAtNormalThreshold() {
        let proposed = SnapGeometry(minX: 0.392, maxX: 0.592, minY: 0.2, maxY: 0.4) // Center is 0.492, dx = 0.008
        // Using normal threshold 0.01
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.activeVerticalGuide, 0.5)
    }
    func test22_ExistingSnapRemainsInsideReleaseThreshold() {
        let proposed = SnapGeometry(minX: 0.385, maxX: 0.585, minY: 0.2, maxY: 0.4) // Center is 0.485, dx = 0.015
        // Using release threshold 0.02 by making it active
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, activeSnapX: .canvasCenter)
        XCTAssertEqual(result.activeVerticalGuide, 0.5)
    }
    func test23_SnapReleasesOutsideHysteresisThreshold() {
        let proposed = SnapGeometry(minX: 0.375, maxX: 0.575, minY: 0.2, maxY: 0.4) // Center is 0.475, dx = 0.025
        // Using release threshold 0.02 by making it active
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, activeSnapX: .canvasCenter)
        XCTAssertNil(result.activeVerticalGuide)
    }
    
    // IDENTITY
    func test24_SnapResultExposesIdentity() {
        let proposed = SnapGeometry(minX: 0.002, maxX: 0.2, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        XCTAssertEqual(result.snappedXType, .canvasEdge(.min))
    }
    
    // Z-ORDER
    func test25_EqualZIndexUsesDeterministicTieBreak() {
        let document = MockupDocument()
        let el1 = CanvasElement(content: .text, zIndex: 1)
        let el2 = CanvasElement(content: .text, zIndex: 1)
        
        document.elements = [el1, el2]
        let sorted1 = document.sortedElements
        
        document.elements = [el2, el1]
        let sorted2 = document.sortedElements
        
        // Sorting should result in the exact same order regardless of array insertion order
        XCTAssertEqual(sorted1[0].id, sorted2[0].id)
        XCTAssertEqual(sorted1[1].id, sorted2[1].id)
        XCTAssertEqual(sorted1[0].id.uuidString < sorted1[1].id.uuidString, true)
    }
    
    // OBJECT-TO-OBJECT
    func test26_CenterToCenter() {
        let id = UUID()
        let other = SnapGeometry(minX: 0.1, maxX: 0.3, minY: 0.1, maxY: 0.3) // Center is 0.2
        let proposed = SnapGeometry(minX: 0.096, maxX: 0.296, minY: 0.5, maxY: 0.7) // Center is 0.196
        
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, otherObjects: [id: other])
        XCTAssertEqual(result.activeVerticalGuide, 0.2)
        XCTAssertEqual(result.snappedXType, .objectCenter(id))
    }
    
    func test27_VerticalEdgeToEdge() {
        let id = UUID()
        let other = SnapGeometry(minX: 0.1, maxX: 0.3, minY: 0.1, maxY: 0.3)
        let proposed = SnapGeometry(minX: 0.295, maxX: 0.5, minY: 0.5, maxY: 0.7) // Left edge is 0.295
        
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, otherObjects: [id: other])
        XCTAssertEqual(result.activeVerticalGuide, 0.3) // Snapped to other's maxX
        XCTAssertEqual(result.snappedXType, .objectAdjacentEdge(id, .max))
    }
    
    func test28_HorizontalEdgeToEdge() {
        let id = UUID()
        let other = SnapGeometry(minX: 0.1, maxX: 0.3, minY: 0.1, maxY: 0.3) // minY 0.1, maxY 0.3
        let proposed = SnapGeometry(minX: 0.5, maxX: 0.7, minY: 0.306, maxY: 0.506) // Top edge is 0.306
        
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, otherObjects: [id: other])
        XCTAssertEqual(result.activeHorizontalGuide, 0.3) // Snapped to other's maxY
        XCTAssertEqual(result.snappedYType, .objectAdjacentEdge(id, .max))
    }
    
    func test29_CompetingObjectCandidatesResolveDeterministically() {
        let id1 = UUID()
        let id2 = UUID()
        let other1 = SnapGeometry(minX: 0.1, maxX: 0.3, minY: 0.1, maxY: 0.3) // Center 0.2
        let other2 = SnapGeometry(minX: 0.6, maxX: 0.8, minY: 0.1, maxY: 0.3) // Center 0.7
        
        let proposed = SnapGeometry(minX: 0.103, maxX: 0.303, minY: 0.5, maxY: 0.7) // center 0.203 (dx = -0.003 to other1)
        
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, otherObjects: [id1: other1, id2: other2])
        
        XCTAssertEqual(result.activeVerticalGuide, 0.2)
        XCTAssertEqual(result.snappedXType, .objectCenter(id1))
    }
    
    func test29b_ObjectDictionaryInsertionOrderInvariance() {
        let id1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let id2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        
        // Exact same distance to two different objects
        let other1 = SnapGeometry(minX: 0.1, maxX: 0.3, minY: 0.1, maxY: 0.3) // Center 0.2
        let other2 = SnapGeometry(minX: 0.1, maxX: 0.3, minY: 0.1, maxY: 0.3) // Center 0.2
        
        let proposed = SnapGeometry(minX: 0.096, maxX: 0.296, minY: 0.5, maxY: 0.7) // Center 0.196
        
        // Even if Dictionary iterates them backwards, evaluateSnap's tie-break should pick the lower UUID.
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, otherObjects: [id1: other1, id2: other2])
        
        XCTAssertEqual(result.snappedXType, .objectCenter(id1))
    }
    
    func test30_AnchorIdentityDifferentiatesHysteresis() {
        let id = UUID()
        let other = SnapGeometry(minX: 0.1, maxX: 0.3, minY: 0.1, maxY: 0.3)
        
        // proposed width is 0.1.
        // minX is 0.115 (diff 0.015 to other minX -> inside release, outside entry)
        // maxX is 0.215 (diff 0.085 to other maxX -> far outside both)
        let proposed = SnapGeometry(minX: 0.115, maxX: 0.215, minY: 0.1, maxY: 0.3)
        
        // Test A: active is .min. It gets 0.02 release threshold, so it snaps.
        let resultA = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, activeSnapX: .objectMatchingEdge(id, .min), otherObjects: [id: other])
        XCTAssertEqual(resultA.activeVerticalGuide, 0.1)
        XCTAssertEqual(resultA.snappedXType, .objectMatchingEdge(id, .min))
        
        // Test B: active is .max. .max is far away.
        // .min is 0.015 away. Since active is .max, .min should NOT inherit the release threshold.
        // It remains at 0.01 entry threshold and fails to snap.
        let resultB = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: .zero, proposedTranslation: .zero, thresholdX: 0.01, thresholdY: 0.01, releaseThresholdX: 0.02, releaseThresholdY: 0.02, activeSnapX: .objectMatchingEdge(id, .max), otherObjects: [id: other])
        XCTAssertNil(resultB.activeVerticalGuide)
        XCTAssertNil(resultB.snappedXType)
    }
    
    func test31_NonZeroOriginalOffsetMaintainsDelta() {
        // If the object starts at 0.1 offset (center is 0.6)
        let proposed = SnapGeometry(minX: 0.1, maxX: 0.3, minY: 0.1, maxY: 0.3) // Center 0.2
        let originalOffset = CGSize(width: 0.1, height: 0.0)
        
        // We drag by -0.09. Center is now 0.11
        // We evaluate against canvas edge 0.0, target is 0.0, we want minX to snap to 0.0.
        // minX is 0.1, translated by -0.09, minX becomes 0.01.
        // 0.01 < 0.02 threshold, so it snaps by -0.01.
        // Final drag translation should be -0.1.
        // Corrected offset should be original (0.1) + translation (-0.1) = 0.0
        
        let result = SnapEngine.evaluateSnap(proposedGeometry: proposed, originalOffset: originalOffset, proposedTranslation: CGSize(width: -0.09, height: 0), thresholdX: 0.02, thresholdY: 0.02, releaseThresholdX: 0.02, releaseThresholdY: 0.02)
        
        XCTAssertEqual(result.activeVerticalGuide, 0.0)
        XCTAssertEqual(result.snappedXType, .canvasEdge(.min))
        XCTAssertEqual(result.correctedOffset.width, 0.0, accuracy: 0.0001)
    }
}
