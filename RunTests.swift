import Foundation

// Copying necessary structs to run the logic here
enum CanvasOrientation: String, CaseIterable {
    case portrait = "Portrait"
    case landscape = "Landscape"
}

enum CanvasRatio: String, CaseIterable {
    case original = "Original"
    case square = "1:1"
    
    // Portrait Ratios
    case fourToFive = "4:5"
    case fiveToSeven = "5:7"
    case threeToFour = "3:4"
    case twoToThree = "2:3"
    case nineToSixteen = "9:16"
    
    // Landscape Ratios
    case fiveToFour = "5:4"
    case sevenToFive = "7:5"
    case fourToThree = "4:3"
    case threeToTwo = "3:2"
    case sixteenToNine = "16:9"
    
    func ratio(for orientation: CanvasOrientation) -> CGFloat {
        switch self {
        case .original: return 1.0
        case .square: return 1.0
        
        case .fourToFive: return orientation == .portrait ? 4.0 / 5.0 : 5.0 / 4.0
        case .fiveToSeven: return orientation == .portrait ? 5.0 / 7.0 : 7.0 / 5.0
        case .threeToFour: return orientation == .portrait ? 3.0 / 4.0 : 4.0 / 3.0
        case .twoToThree: return orientation == .portrait ? 2.0 / 3.0 : 3.0 / 2.0
        case .nineToSixteen: return orientation == .portrait ? 9.0 / 16.0 : 16.0 / 9.0
            
        case .fiveToFour: return orientation == .landscape ? 5.0 / 4.0 : 4.0 / 5.0
        case .sevenToFive: return orientation == .landscape ? 7.0 / 5.0 : 5.0 / 7.0
        case .fourToThree: return orientation == .landscape ? 4.0 / 3.0 : 3.0 / 4.0
        case .threeToTwo: return orientation == .landscape ? 3.0 / 2.0 : 2.0 / 3.0
        case .sixteenToNine: return orientation == .landscape ? 16.0 / 9.0 : 9.0 / 16.0
        }
    }
}

var testsExecuted = 0
var testsPassed = 0
var testsFailed = 0

func assertEqual(_ a: CGFloat, _ b: CGFloat, accuracy: CGFloat, message: String) {
    testsExecuted += 1
    if abs(a - b) <= accuracy {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("FAIL: \(message) (expected \(b), got \(a))")
    }
}

print("Running Automated Tests...")

let maxDim: CGFloat = 3000.0

// Test Ratios
for ratio in CanvasRatio.allCases {
    for orientation in CanvasOrientation.allCases {
        let val = ratio.ratio(for: orientation)
        
        var targetWidth: CGFloat = 0
        var targetHeight: CGFloat = 0
        
        if val >= 1.0 {
            targetWidth = maxDim
            targetHeight = maxDim / val
        } else {
            targetHeight = maxDim
            targetWidth = maxDim * val
        }
        
        let maxResult = max(targetWidth, targetHeight)
        assertEqual(maxResult, maxDim, accuracy: 0.1, message: "Ratio \(ratio.rawValue) in \(orientation.rawValue) failed dimension test")
    }
}

// Result
print("Tests executed: \(testsExecuted)")
print("Passed: \(testsPassed)")
print("Failed: \(testsFailed)")
