// Sprint0_BaselineTests.swift
// Screen MockupTests
//
// Baseline characterization and regression tests for Sprint 0.
// These tests establish verifiable behaviour before any architectural changes.
// No new product features are introduced. No third-party dependencies are added.

import XCTest
import SwiftUI
import CoreGraphics
@testable import Screen_Mockup

// MARK: - Test Fixture Factory

/// Creates small, deterministic test assets and documents.
/// Lives only in the test target. Does not duplicate or replace the production model.
enum TestFixture {

    /// A deterministic solid-colour UIImage produced via UIGraphicsImageRenderer (no disk I/O).
    static func makeTinyImage(color: UIColor = .red, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Deterministic UUIDs for stable, reproducible test fixtures.
    static let elementID_A = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    static let elementID_B = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    static let elementID_C = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
}

// MARK: - §3.1 MockupDocument Baseline Tests

@MainActor
final class Sprint0_MockupDocumentTests: XCTestCase {

    func testDocumentDefaults() {
        let doc = MockupDocument()
        XCTAssertEqual(doc.background, .none, "Default background should be .none")
        XCTAssertEqual(doc.backgroundOpacity, 1.0, "Default backgroundOpacity should be 1.0")
        XCTAssertEqual(doc.canvasRatio, .original, "Default canvasRatio should be .original")
        XCTAssertEqual(doc.canvasOrientation, .portrait, "Default canvasOrientation should be .portrait")
        XCTAssertTrue(doc.elements.isEmpty, "Default elements should be empty")
        XCTAssertNil(doc.selectedElementID, "Default selectedElementID should be nil")
        XCTAssertNil(doc.editingTextElementID, "Default editingTextElementID should be nil")
    }

    func testAddElement() {
        let doc = MockupDocument()
        let element = CanvasElement(id: TestFixture.elementID_A, content: .sfSymbol, zIndex: 0)
        doc.elements.append(element)
        XCTAssertEqual(doc.elements.count, 1)
        XCTAssertEqual(doc.elements[0].id, TestFixture.elementID_A)
    }

    func testRemoveElement() {
        let doc = MockupDocument()
        let elementA = CanvasElement(id: TestFixture.elementID_A, content: .sfSymbol, zIndex: 0)
        let elementB = CanvasElement(id: TestFixture.elementID_B, content: .sfSymbol, zIndex: 1)
        doc.elements = [elementA, elementB]
        doc.elements.removeAll { $0.id == TestFixture.elementID_A }
        XCTAssertEqual(doc.elements.count, 1)
        XCTAssertEqual(doc.elements[0].id, TestFixture.elementID_B)
    }

    func testSelectElement() {
        let doc = MockupDocument()
        let element = CanvasElement(id: TestFixture.elementID_A, content: .sfSymbol, zIndex: 0)
        doc.elements.append(element)
        doc.selectedElementID = element.id
        XCTAssertEqual(doc.selectedElementID, TestFixture.elementID_A)
    }

    func testClearSelection() {
        let doc = MockupDocument()
        doc.selectedElementID = TestFixture.elementID_A
        doc.selectedElementID = nil
        XCTAssertNil(doc.selectedElementID)
    }

    func testResetTransform() {
        let doc = MockupDocument()
        let element = CanvasElement(content: .sfSymbol, transform: ElementTransform(normalizedPosition: CGPoint(x: 0.3, y: -0.1), scale: 2.5, rotationDegrees: 0, opacity: 1), zIndex: 0)
        doc.elements = [element]
        doc.selectedElementID = element.id
        doc.resetTransform()
        XCTAssertEqual(doc.elements[0].transform.scale, 1.0, accuracy: 0.0001)
        XCTAssertEqual(doc.elements[0].transform.normalizedPosition, CGPoint(x: 0.5, y: 0.5))
    }
}

// MARK: - §3.2 CanvasElement Baseline Tests

@MainActor
final class Sprint0_CanvasElementTests: XCTestCase {

    func testElementIDStability() {
        var element = CanvasElement(
            id: TestFixture.elementID_A,
            content: .sfSymbol,
            transform: ElementTransform(normalizedPosition: CGPoint(x: 0.5, y: 0.5), scale: 1.0, rotationDegrees: 0, opacity: 1),
            zIndex: 0
        )
        let idBefore = element.id
        element.transform.normalizedPosition = CGPoint(x: 0.9, y: 0.1)
        element.transform.scale = 3.0
        element.zIndex = 99
        XCTAssertEqual(element.id, idBefore, "Element ID must not change after property mutations")
    }

    func testNormalizedPositionAndScaleRetained() {
        let pos = CGPoint(x: 0.25, y: 0.75)
        let scale: CGFloat = 0.42
        let element = CanvasElement(
            id: TestFixture.elementID_B,
            content: .sfSymbol,
            transform: ElementTransform(normalizedPosition: pos, scale: scale, rotationDegrees: 0, opacity: 1),
            zIndex: 3
        )
        XCTAssertEqual(element.transform.normalizedPosition.x, 0.25, accuracy: 0.0001)
        XCTAssertEqual(element.transform.normalizedPosition.y, 0.75, accuracy: 0.0001)
        XCTAssertEqual(element.transform.scale, 0.42, accuracy: 0.0001)
        XCTAssertEqual(element.zIndex, 3)
    }

    func testElementContentTypesHandled() {
        // Image
        let assetID = UUID()
        let imageRef = MediaReference(assetID: assetID, kind: .image, pixelSize: CGSize(width: 10, height: 10), duration: nil)
        let imageElement = CanvasElement(content: .image(imageRef))
        if case .image(let ref) = imageElement.content {
            XCTAssertEqual(ref.assetID, assetID)
            XCTAssertEqual(ref.pixelSize, CGSize(width: 10, height: 10))
        } else {
            XCTFail("Expected .image content")
        }
        
        // Device
        let deviceElement = CanvasElement(content: .device(DeviceElementData(media: imageRef, bezelStyle: .iphone17White, showStatusBar: true)))
        if case .device(let data) = deviceElement.content {
            XCTAssertEqual(data.media.assetID, assetID)
            XCTAssertEqual(data.bezelStyle, .iphone17White)
        } else {
            XCTFail("Expected .device content")
        }

        // Text
        let textData = CanvasElement.TextData(string: "Baseline", fontName: "System", color: .white)
        let textElement = CanvasElement(content: .text(textData))
        if case .text(let t) = textElement.content {
            XCTAssertEqual(t.string, "Baseline")
            XCTAssertEqual(t.fontName, "System")
        } else {
            XCTFail("Expected .text content")
        }

        // SF Symbol
        let symbolElement = CanvasElement(content: .sfSymbol)
        if case .sfSymbol = symbolElement.content {
            // pass – expected
        } else {
            XCTFail("Expected .sfSymbol content")
        }
    }

    func testZIndexSortingDeterministic() {
        let doc = MockupDocument()
        let e1 = CanvasElement(id: TestFixture.elementID_C, content: .sfSymbol, zIndex: 5)
        let e2 = CanvasElement(id: TestFixture.elementID_A, content: .sfSymbol, zIndex: 1)
        let e3 = CanvasElement(id: TestFixture.elementID_B, content: .sfSymbol, zIndex: 10)
        doc.elements = [e3, e1, e2]
        let sorted = doc.sortedElements
        XCTAssertEqual(sorted.map(\.zIndex), [1, 5, 10], "sortedElements must order by zIndex ascending")
        XCTAssertEqual(sorted[0].id, TestFixture.elementID_A)
        XCTAssertEqual(sorted[1].id, TestFixture.elementID_C)
        XCTAssertEqual(sorted[2].id, TestFixture.elementID_B)
    }
}

// MARK: - §3.3 Layer Ordering Tests

@MainActor
final class Sprint0_LayerOrderingTests: XCTestCase {

    func testSortedElementsOrder() {
        let doc = MockupDocument()
        let front  = CanvasElement(content: .sfSymbol, zIndex: 10)
        let back   = CanvasElement(content: .sfSymbol, zIndex: -5)
        let middle = CanvasElement(content: .sfSymbol, zIndex: 2)
        doc.elements = [front, back, middle]
        let sorted = doc.sortedElements
        XCTAssertEqual(sorted[0].id, back.id,   "z=-5 should be first (bottom)")
        XCTAssertEqual(sorted[1].id, middle.id, "z=2 should be second")
        XCTAssertEqual(sorted[2].id, front.id,  "z=10 should be last (top)")
    }

    /// Baseline characterisation: `sortedElements` uses UUID-string tie-breaking when zIndex values are equal.
    /// Evidence in production code (MockupDocument.sortedElements):
    ///   `if $0.zIndex != $1.zIndex { return $0.zIndex < $1.zIndex }`
    ///   `return $0.id.uuidString < $1.id.uuidString`
    /// This is contracted behaviour and is tested here as a stable baseline.
    func testEqualZIndexTieBreakByUUID() {
        let idLow  = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let idHigh = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!
        let doc = MockupDocument()
        let eLow  = CanvasElement(id: idLow,  content: .sfSymbol, zIndex: 1)
        let eHigh = CanvasElement(id: idHigh, content: .sfSymbol, zIndex: 1)

        // Insert in reverse order to confirm insertion order does not affect result.
        doc.elements = [eHigh, eLow]
        let sorted1 = doc.sortedElements
        doc.elements = [eLow, eHigh]
        let sorted2 = doc.sortedElements

        XCTAssertEqual(sorted1[0].id, idLow,  "Lower UUID string should come first (bottom of stack)")
        XCTAssertEqual(sorted1[0].id, sorted2[0].id, "Sort order must be independent of insertion order")
        XCTAssertEqual(sorted1[1].id, sorted2[1].id)
    }

    func testSelectionDoesNotAffectSortOrder() {
        let doc = MockupDocument()
        let e1 = CanvasElement(id: TestFixture.elementID_A, content: .sfSymbol, zIndex: 0)
        let e2 = CanvasElement(id: TestFixture.elementID_B, content: .sfSymbol, zIndex: 1)
        doc.elements = [e1, e2]

        let sortedWithoutSelection = doc.sortedElements.map(\.id)
        doc.selectedElementID = e2.id
        let sortedWithSelection = doc.sortedElements.map(\.id)

        XCTAssertEqual(sortedWithoutSelection, sortedWithSelection,
            "selectedElementID must not alter the sort order of sortedElements")
    }
}

// MARK: - §3.4 SnapEngine Gap Tests

@MainActor
final class Sprint0_SnapEngineGapTests: XCTestCase {

    // Existing tests (Phase81) cover: center X/Y, edges, safe margins, bounding geometry,
    // determinism, hysteresis, object-to-object, multi-candidate, and original offset.
    // The following tests fill documented gaps.

    /// Verifies the threshold check is strictly less-than (<), not <=.
    /// When distance == threshold exactly, no snap should occur.
    func testSnapNoResultWhenExactlyAtThresholdBoundary() {
        // centerX = 0.49, canvas center = 0.5, distance = 0.01 exactly == thresholdX
        let proposed = SnapGeometry(minX: 0.39, maxX: 0.59, minY: 0.3, maxY: 0.5)
        let result = SnapEngine.evaluateSnap(
            proposedGeometry: proposed,
            originalOffset: .zero,
            proposedTranslation: .zero,
            thresholdX: 0.01,
            thresholdY: 0.01,
            releaseThresholdX: 0.02,
            releaseThresholdY: 0.02
        )
        XCTAssertNil(result.snappedXType, "Snap must not occur when distance exactly equals threshold (strict <)")
    }

    /// Verifies that a snap on X does not produce a non-zero correction on Y, and vice versa.
    func testBothAxesAreIndependent() {
        // centerX = 0.498 (dx 0.002 → snaps), centerY = 0.3 (dy 0.2 → does not snap)
        let proposed = SnapGeometry(minX: 0.398, maxX: 0.598, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(
            proposedGeometry: proposed,
            originalOffset: .zero,
            proposedTranslation: .zero,
            thresholdX: 0.01,
            thresholdY: 0.01,
            releaseThresholdX: 0.02,
            releaseThresholdY: 0.02
        )
        XCTAssertNotNil(result.snappedXType,  "X should snap to canvas center")
        XCTAssertNil(result.snappedYType,     "Y should not snap")
        XCTAssertEqual(result.correctedOffset.height, 0.0, accuracy: 0.0001,
            "Y correction must be zero when Y does not snap")
    }

    /// Verifies that a zero-size geometry (point) does not crash and snaps correctly.
    func testZeroSizeGeometryDoesNotCrash() {
        // Point at canvas center (0.5, 0.5) – distance 0 to canvas center on both axes
        let proposed = SnapGeometry(minX: 0.5, maxX: 0.5, minY: 0.5, maxY: 0.5)
        let result = SnapEngine.evaluateSnap(
            proposedGeometry: proposed,
            originalOffset: .zero,
            proposedTranslation: .zero,
            thresholdX: 0.01,
            thresholdY: 0.01,
            releaseThresholdX: 0.02,
            releaseThresholdY: 0.02
        )
        XCTAssertEqual(result.snappedXType, .canvasCenter)
        XCTAssertEqual(result.snappedYType, .canvasCenter)
        XCTAssertEqual(result.correctedOffset.width,  0.0, accuracy: 0.0001)
        XCTAssertEqual(result.correctedOffset.height, 0.0, accuracy: 0.0001)
    }

    /// Verifies correctedOffset = originalOffset + proposedTranslation + snapDelta.
    func testSnapTranslationComposesCorrectly() {
        // Geometry centred at (0.3, 0.3). Translation (0.196, 0.0) → translated centerX = 0.496.
        // Snap to canvas center (0.5): snapDelta.x = 0.004.
        // correctedOffset.width = 0.0 + 0.196 + 0.004 = 0.200
        let proposed = SnapGeometry(minX: 0.2, maxX: 0.4, minY: 0.2, maxY: 0.4)
        let result = SnapEngine.evaluateSnap(
            proposedGeometry: proposed,
            originalOffset: CGSize(width: 0.0, height: 0.0),
            proposedTranslation: CGSize(width: 0.196, height: 0.0),
            thresholdX: 0.01,
            thresholdY: 0.01,
            releaseThresholdX: 0.02,
            releaseThresholdY: 0.02
        )
        XCTAssertEqual(result.snappedXType, .canvasCenter)
        XCTAssertEqual(result.correctedOffset.width,  0.2, accuracy: 0.0001,
            "correctedOffset = originalOffset + proposedTranslation + snapDelta")
        XCTAssertEqual(result.correctedOffset.height, 0.0, accuracy: 0.0001)
    }
}

// MARK: - §3.5 Export Size Tests

@MainActor
final class Sprint0_ExportSizeTests: XCTestCase {

    // Tests `MockupExporter.calculateCanvasSize(ratio:orientation:media:)` directly.
    // This validates size calculation in isolation without triggering any export side-effects.

    func testPortraitAspectRatioProducesCorrectDimensions() {
        // 4:5 portrait → ratio = 0.8 < 1.0 → height = 3000, width = 3000 * 0.8 = 2400
        let size = MockupExporter.calculateCanvasSize(ratio: .fourToFive, orientation: .portrait, media: nil)
        XCTAssertEqual(size.height, 3000, accuracy: 1.0)
        XCTAssertEqual(size.width,  2400, accuracy: 1.0)
    }

    func testLandscapeAspectRatioProducesCorrectDimensions() {
        // 9:16 landscape → ratio = 16/9 > 1 → width = 3000, height = round(3000 / (16/9)) = 1688
        let size = MockupExporter.calculateCanvasSize(ratio: .nineToSixteen, orientation: .landscape, media: nil)
        XCTAssertEqual(size.width, 3000, accuracy: 1.0)
        let expected = round(3000.0 / (16.0 / 9.0))
        XCTAssertEqual(size.height, expected, accuracy: 1.0)
    }

    func testSquareRatioProducesEqualDimensions() {
        let size = MockupExporter.calculateCanvasSize(ratio: .square, orientation: .portrait, media: nil)
        XCTAssertEqual(size.width,  3000, accuracy: 1.0)
        XCTAssertEqual(size.height, 3000, accuracy: 1.0)
    }

    func testNoZeroOrNegativeDimensionForAnyRatioAndOrientation() {
        // .original without media falls back to 9/16 inside calculateCanvasSize.
        for ratio in CanvasRatio.allCases {
            for orientation in CanvasOrientation.allCases {
                let size = MockupExporter.calculateCanvasSize(ratio: ratio, orientation: orientation, media: nil)
                XCTAssertGreaterThan(size.width,  0, "Width must be > 0 for \(ratio) \(orientation)")
                XCTAssertGreaterThan(size.height, 0, "Height must be > 0 for \(ratio) \(orientation)")
            }
        }
    }

    func testMaxDimensionIs3000ForAllRatiosAndOrientations() {
        for ratio in CanvasRatio.allCases {
            for orientation in CanvasOrientation.allCases {
                let size = MockupExporter.calculateCanvasSize(ratio: ratio, orientation: orientation, media: nil)
                let maxDim = max(size.width, size.height)
                XCTAssertEqual(maxDim, 3000, accuracy: 1.0,
                    "Max dimension must be 3000 for \(ratio) \(orientation)")
            }
        }
    }

    func testCalculationIsDeterministic() {
        let size1 = MockupExporter.calculateCanvasSize(ratio: .twoToThree, orientation: .portrait, media: nil)
        let size2 = MockupExporter.calculateCanvasSize(ratio: .twoToThree, orientation: .portrait, media: nil)
        XCTAssertEqual(size1.width,  size2.width)
        XCTAssertEqual(size1.height, size2.height)
    }
}

// MARK: - §3.6 Preview/Export Parity + §3.7 Export Smoke Tests

final class Sprint0_ExportRenderingTests: XCTestCase {

    // Draws a CGImage into a known RGBA context and returns the raw pixel bytes.
    // Used for deterministic pixel-level comparisons.
    private func pixelBytes(from cgImage: CGImage) -> [UInt8]? {
        let w = cgImage.width
        let h = cgImage.height
        guard w > 0, h > 0 else { return nil }
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * w
        var data = [UInt8](repeating: 0, count: h * bytesPerRow)
        guard let ctx = CGContext(
            data: &data,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
        return data
    }

    // §3.6 – Preview/export parity
    //
    // Code inspection evidence:
    //   • MockupExporter.renderImage: creates MockupCompositionView(document:canvasSize:) with isEditor default = false.
    //   • CanvasElementView.body: selection chrome rendered only when `isSelected && isEditor` (both true).
    //   • CanvasOverlayLayer passes isEditor down to every CanvasElementView.
    //   • Therefore: with isEditor: false, no selection chrome is ever rendered regardless of selectedElementID.
    //
    // This test renders the same composition twice with isEditor: false and different selectedElementID values,
    // then compares pixel output to confirm they are identical.
    @MainActor
    func testExportCompositionIsUnaffectedBySelectionState() async throws {
        let doc = MockupDocument()
        // Solid background only – avoids font/asset rendering non-determinism.
        doc.background = .solid(Color(red: 0.6, green: 0.2, blue: 0.8))
        let canvasSize = CGSize(width: 20, height: 25)

        func render(selectedID: UUID?) -> CGImage? {
            doc.selectedElementID = selectedID
            let view = MockupCompositionView(document: doc, canvasSize: canvasSize, isEditor: false)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0
            renderer.proposedSize = .init(canvasSize)
            renderer.isOpaque = true
            return renderer.cgImage
        }

        guard let cgImageA = render(selectedID: nil) else {
            XCTFail("Renderer produced nil image without selection"); return
        }
        guard let cgImageB = render(selectedID: UUID()) else {
            XCTFail("Renderer produced nil image with selection"); return
        }
        guard let bytesA = pixelBytes(from: cgImageA),
              let bytesB = pixelBytes(from: cgImageB) else {
            XCTFail("Could not extract pixel data"); return
        }
        XCTAssertEqual(bytesA, bytesB,
            "Export pixel output must be identical regardless of selectedElementID when isEditor is false")
    }

    // §3.7 – Stillbild smoke tests

    @MainActor
    func testImageRendererProducesNonNilResult() async throws {
        let doc = MockupDocument()
        doc.background = .solid(.blue)
        let canvasSize = MockupExporter.calculateCanvasSize(ratio: .square, orientation: .portrait, media: nil)
        let view = MockupCompositionView(document: doc, canvasSize: canvasSize, isEditor: false)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        renderer.proposedSize = .init(canvasSize)
        renderer.isOpaque = false
        XCTAssertNotNil(renderer.cgImage, "ImageRenderer must produce a non-nil cgImage for a simple composition")
    }

    @MainActor
    func testRenderedImageHasExpectedPixelDimensions() async throws {
        let doc = MockupDocument()
        doc.background = .solid(.green)
        let expectedSize = MockupExporter.calculateCanvasSize(ratio: .fourToFive, orientation: .portrait, media: nil)
        // expectedSize: width=2400, height=3000
        let view = MockupCompositionView(document: doc, canvasSize: expectedSize, isEditor: false)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        renderer.proposedSize = .init(expectedSize)
        guard let cgImage = renderer.cgImage else {
            XCTFail("Renderer produced nil image"); return
        }
        XCTAssertEqual(CGFloat(cgImage.width),  expectedSize.width,  accuracy: 1.0,
            "Rendered width must match calculated canvas width")
        XCTAssertEqual(CGFloat(cgImage.height), expectedSize.height, accuracy: 1.0,
            "Rendered height must match calculated canvas height")
    }

    /// Renders a composition with background .none and verifies the centre pixel has near-zero alpha,
    /// confirming that alpha is preserved through the ImageRenderer pipeline.
    ///
    /// Limitation: If the SwiftUI rendering pipeline or the simulator's colour management prevents
    /// a fully transparent result, this test will fail. In that case the failure is documented in the
    /// Sprint 0 completion report and the test is removed rather than replaced with a trivial assertion.
    @MainActor
    func testTransparentCanvasPreservesAlpha() async throws {
        let doc = MockupDocument()
        doc.background = .none  // → Color.clear in MockupCompositionView
        let canvasSize = CGSize(width: 10, height: 10)

        let view = MockupCompositionView(document: doc, canvasSize: canvasSize, isEditor: false)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        renderer.proposedSize = .init(canvasSize)
        renderer.isOpaque = false

        guard let cgImage = renderer.cgImage else {
            XCTFail("Renderer produced nil image for transparent canvas"); return
        }
        guard let bytes = pixelBytes(from: cgImage) else {
            XCTFail("Could not extract pixel data from rendered image"); return
        }

        // Sample the centre pixel (5,5) in a 10×10 grid. premultipliedLast → A is at byte offset +3.
        let centerX = 5
        let centerY = 5
        let bytesPerRow = 4 * cgImage.width
        let byteIndex = (centerY * bytesPerRow) + (centerX * 4)
        guard byteIndex + 3 < bytes.count else {
            XCTFail("Pixel index out of bounds"); return
        }
        let alpha = CGFloat(bytes[byteIndex + 3]) / 255.0
        XCTAssertLessThan(alpha, 0.05,
            "Centre pixel alpha must be near-zero (transparent) for a .none background composition")
    }
}

