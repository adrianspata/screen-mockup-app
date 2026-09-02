import SwiftUI

struct AssetImageView: View {
    let reference: MediaReference
    @Environment(\.projectAssetStore) private var assetStore
    @State private var uiImage: UIImage?
    
    var body: some View {
        Group {
            if let image = uiImage ?? assetStore?.cachedImage(for: reference.assetID) {
                Image(uiImage: image)
                    .resizable()
            } else {
                // Dimensions stabilizing placeholder
                Color.clear
                    .aspectRatio(reference.pixelSize ?? CGSize(width: 1, height: 1), contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
                    .task {
                        do {
                            uiImage = try await assetStore?.loadImage(for: reference.assetID)
                        } catch {
                            print("Failed to load image \(reference.assetID): \(error)")
                        }
                    }
            }
        }
    }
}

// Environment key for ProjectAssetStore
private struct ProjectAssetStoreKey: EnvironmentKey {
    static let defaultValue: ProjectAssetStore? = nil
}

extension EnvironmentValues {
    var projectAssetStore: ProjectAssetStore? {
        get { self[ProjectAssetStoreKey.self] }
        set { self[ProjectAssetStoreKey.self] = newValue }
    }
}
