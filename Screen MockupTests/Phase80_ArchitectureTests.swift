import XCTest
@testable import Screen_Mockup

final class Phase80_ArchitectureTests: XCTestCase {

    func testElementIdentityAndStorage() {
        let document = MockupDocument()
        XCTAssertTrue(document.elements.isEmpty)
        
        let elementA = CanvasElement(content: .text, zIndex: 0)
        let elementB = CanvasElement(content: .text, zIndex: 1)
        
        // Use append instead of addElement as MockupDocument uses raw array
        document.elements.append(elementA)
        document.elements.append(elementB)
        
        XCTAssertEqual(document.elements.count, 2)
        XCTAssertEqual(document.elements[0].id, elementA.id)
        XCTAssertEqual(document.elements[1].id, elementB.id)
    }
    
    func testElementMutationAndOrdering() {
        var element = CanvasElement(content: .sfSymbol, zIndex: 1)
        
        // Canvas local transforms
        XCTAssertEqual(element.normalizedPosition.x, 0.5)
        XCTAssertEqual(element.normalizedPosition.y, 0.5)
        XCTAssertEqual(element.scale, 1.0)
        
        element.normalizedPosition = CGPoint(x: 0.25, y: 0.75)
        element.scale = 1.5
        element.zIndex = 5
        
        XCTAssertEqual(element.normalizedPosition.x, 0.25)
        XCTAssertEqual(element.normalizedPosition.y, 0.75)
        XCTAssertEqual(element.scale, 1.5)
        XCTAssertEqual(element.zIndex, 5)
    }
    
    func testAuthoritativeSelection() {
        let document = MockupDocument()
        XCTAssertNil(document.selectedElementID)
        
        let element = CanvasElement(content: .text, zIndex: 0)
        document.elements.append(element)
        document.selectedElementID = element.id
        
        XCTAssertEqual(document.selectedElementID, element.id)
        
        // Remove selection
        document.selectedElementID = nil
        XCTAssertNil(document.selectedElementID)
    }
    
    func testZOrderSort() {
        let elementFront = CanvasElement(content: .text, zIndex: 10)
        let elementBack = CanvasElement(content: .text, zIndex: -5)
        let elementMiddle = CanvasElement(content: .sfSymbol, zIndex: 2)
        
        let unsorted = [elementFront, elementBack, elementMiddle]
        let sorted = unsorted.sorted(by: { $0.zIndex < $1.zIndex })
        
        XCTAssertEqual(sorted[0].id, elementBack.id)
        XCTAssertEqual(sorted[1].id, elementMiddle.id)
        XCTAssertEqual(sorted[2].id, elementFront.id)
    }
}
