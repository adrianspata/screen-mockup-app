import Foundation
import CoreGraphics

// Dummy representation
struct DrawerState {
    enum State {
        case expanded, collapsed, hidden
    }
    let state: State
    
    func height(safeBottom: CGFloat) -> CGFloat {
        switch state {
        case .expanded: return 330 + safeBottom
        case .collapsed: return 110 + safeBottom
        case .hidden: return 0
        }
    }
}

var testsExecuted = 0
var testsPassed = 0
var testsFailed = 0

func assertEqual(_ a: CGFloat, _ b: CGFloat, message: String) {
    testsExecuted += 1
    if abs(a - b) < 0.1 {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("FAIL: \(message) (expected \(b), got \(a))")
    }
}

print("Running Automated Tests...")

// Drawer Invariance & Safe Area Tests
let safeBottoms: [CGFloat] = [16, 34, 50]
for sb in safeBottoms {
    let expandedH = DrawerState(state: .expanded).height(safeBottom: sb)
    let collapsedH = DrawerState(state: .collapsed).height(safeBottom: sb)
    let hiddenH = DrawerState(state: .hidden).height(safeBottom: sb)
    
    assertEqual(expandedH, 330 + sb, message: "Expanded height with safeBottom \(sb)")
    assertEqual(collapsedH, 110 + sb, message: "Collapsed height with safeBottom \(sb)")
    assertEqual(hiddenH, 0, message: "Hidden height with safeBottom \(sb)")
}

// Result
print("Tests executed: \(testsExecuted)")
print("Passed: \(testsPassed)")
print("Failed: \(testsFailed)")
