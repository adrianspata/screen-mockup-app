import Foundation

enum LoadError: Error, LocalizedError {
    case missingManifest
    case corruptManifest(Error)
    case unsupportedSchemaVersion(Int)
    case unsupportedBezelStyle(String)
    case unsupportedCanvasRatio(String)
    case unsupportedCanvasOrientation(String)
    case invalidNumericValue(String)
    
    var errorDescription: String? {
        switch self {
        case .missingManifest:
            return "Projektets manifest.json saknas."
        case .corruptManifest(let error):
            return "Projektfilen är skadad eller kan inte läsas: \(error.localizedDescription)"
        case .unsupportedSchemaVersion(let version):
            return "Projektet sparades med en nyare version av appen (schema v\(version)) och kan inte öppnas."
        case .unsupportedBezelStyle(let style):
            return "Ogiltig bezel style: \(style)"
        case .unsupportedCanvasRatio(let ratio):
            return "Ogiltig canvas ratio: \(ratio)"
        case .unsupportedCanvasOrientation(let orientation):
            return "Ogiltig canvas orientation: \(orientation)"
        case .invalidNumericValue(let details):
            return "Ogiltigt numeriskt värde upptäcktes: \(details)"
        }
    }
}
