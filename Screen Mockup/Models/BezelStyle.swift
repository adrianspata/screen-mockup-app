import Foundation

enum BezelStyle: String, CaseIterable, Equatable, Codable {
    case none = "None"
    
    // iPhone 17
    case iphone17Black = "iPhone 17 (Black)"
    case iphone17Lavender = "iPhone 17 (Lavender)"
    case iphone17MistBlue = "iPhone 17 (Mist Blue)"
    case iphone17Sage = "iPhone 17 (Sage)"
    case iphone17White = "iPhone 17 (White)"
    
    // iPhone 17 Pro
    case iphone17ProCosmicOrange = "iPhone 17 Pro (Cosmic Orange)"
    case iphone17ProDeepBlue = "iPhone 17 Pro (Deep Blue)"
    case iphone17ProSilver = "iPhone 17 Pro (Silver)"
    
    // iPhone Air
    case iphoneAirCloudWhite = "iPhone Air (Cloud White)"
    case iphoneAirLightGold = "iPhone Air (Light Gold)"
    case iphoneAirSkyBlue = "iPhone Air (Sky Blue)"
    case iphoneAirSpaceBlack = "iPhone Air (Space Black)"
    
    var imageName: String? {
        switch self {
        case .none: return nil
            
        case .iphone17Black: return "iphone-17-black"
        case .iphone17Lavender: return "iphone-17-lavender"
        case .iphone17MistBlue: return "iphone-17-mist-blue"
        case .iphone17Sage: return "iphone-17-sage"
        case .iphone17White: return "iphone-17-white"
            
        case .iphone17ProCosmicOrange: return "iphone-17-pro-cosmic-orange"
        case .iphone17ProDeepBlue: return "iphone-17-pro-deep-blue"
        case .iphone17ProSilver: return "iphone-17-pro-silver"
            
        case .iphoneAirCloudWhite: return "iphone-air-cloud-white"
        case .iphoneAirLightGold: return "iphone-air-light-gold"
        case .iphoneAirSkyBlue: return "iphone-air-sky-blue"
        case .iphoneAirSpaceBlack: return "iphone-air-space-black"
        }
    }
    
    var spec: DeviceSpec? {
        switch self {
        case .none: return nil
        case .iphoneAirCloudWhite, .iphoneAirLightGold, .iphoneAirSkyBlue, .iphoneAirSpaceBlack:
            return .iphoneAir
        default: return .iphone17
        }
    }
    
    var isDark: Bool {
        switch self {
        case .iphone17Black, .iphone17ProDeepBlue, .iphoneAirSpaceBlack:
            return true
        default:
            return false
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let style = BezelStyle(rawValue: rawValue) {
            self = style
        } else {
            // Fallback for older saved presets
            if rawValue.contains("Light") {
                self = .iphone17White
            } else if rawValue.contains("Dark") {
                self = .iphone17Black
            } else {
                self = .none
            }
        }
    }
}
