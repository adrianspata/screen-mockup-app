import XCTest
import UIKit
@testable import Screen_Mockup

final class Phase82_ImagesTests: XCTestCase {
    
    var document: MockupDocument!
    
    override func setUp() {
        super.setUp()
        document = MockupDocument()
    }
    
    override func tearDown() {
        document = nil
        super.tearDown()
    }
    
    func testImageImportCreatesCanvasElement() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        UIGraphicsBeginImageContext(rect.size)
        UIColor.red.setFill()
        UIRectFill(rect)
        let dummyImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        ImageImporter.importImage(dummyImage, into: document)
        
        XCTAssertEqual(document.elements.count, 1)
        
        let element = document.elements[0]
        XCTAssertEqual(document.selectedElementID, element.id)
        
        if case .image(let ref) = element.content {
            XCTAssertEqual(ref.intrinsicSize, CGSize(width: 100, height: 100))
            XCTAssertNotNil(AssetManager.shared.getImage(for: ref.assetID))
        } else {
            XCTFail("Element content should be image")
        }
    }
    
    func testMultipleImagesHaveUniqueZIndex() {
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        UIGraphicsBeginImageContext(rect.size)
        UIColor.blue.setFill()
        UIRectFill(rect)
        let dummyImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        ImageImporter.importImage(dummyImage, into: document)
        ImageImporter.importImage(dummyImage, into: document)
        
        XCTAssertEqual(document.elements.count, 2)
        XCTAssertNotEqual(document.elements[0].zIndex, document.elements[1].zIndex)
    }
    
    func testAssetManager() {
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        UIGraphicsBeginImageContext(rect.size)
        UIColor.green.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let id = AssetManager.shared.store(image: image)
        XCTAssertNotNil(AssetManager.shared.getImage(for: id))
        
        AssetManager.shared.removeImage(for: id)
        XCTAssertNil(AssetManager.shared.getImage(for: id))
    }
}
