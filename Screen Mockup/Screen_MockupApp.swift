//
//  Screen_MockupApp.swift
//  Screen Mockup
//

import SwiftUI

@main
struct Screen_MockupApp: App {
    @State private var session: ProjectSession?
    @State private var loadError: Error?
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let session = session {
                    EditorView(session: session)
                        .environment(\.projectAssetStore, session.assetStore)
                } else if let error = loadError {
                    VStack {
                        Text("Failed to load project")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Button("Start Fresh Project") {
                            createNewProject()
                        }
                        .padding()
                    }
                } else {
                    ProgressView("Loading Project...")
                        .onAppear {
                            loadLatestProject()
                        }
                }
            }
        }
    }
    
    private func loadLatestProject() {
        Task {
            if let latestIDString = UserDefaults.standard.string(forKey: "latestProjectID"),
               let projectID = UUID(uuidString: latestIDString) {
                do {
                    let s = try ProjectSession(projectID: projectID)
                    await s.load()
                    if case .error(let err) = s.state {
                        self.loadError = err
                    } else {
                        self.session = s
                    }
                } catch {
                    createNewProject()
                }
            } else {
                createNewProject()
            }
        }
    }
    
    private func createNewProject() {
        do {
            self.session = try ProjectSession.createNew()
            self.loadError = nil
        } catch {
            self.loadError = error
        }
    }
}
