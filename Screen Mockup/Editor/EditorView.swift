import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mp4")
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

extension Color {
    static let editorBackground = Color(red: 17/255, green: 17/255, blue: 22/255)
    static let panelBackground = Color(red: 34/255, green: 34/255, blue: 37/255)
    static let controlBackground = Color(red: 48/255, green: 48/255, blue: 52/255)
    static let screenyOrange = Color(red: 255/255, green: 146/255, blue: 46/255)
}

enum DrawerState {
    case expanded
    case collapsed
}

struct EditorView: View {
    @State private var document = MockupDocument()
    @State private var selectedItem: PhotosPickerItem?
    
    enum EditorTool: String, CaseIterable {
        case presets = "Presets"
        case background = "Background"
        case images = "Images"
        case ratio = "Ratio"
        case text = "Text"
        case zoom = "Zoom"
        case bezel = "Bezel"
        
        var icon: String {
            switch self {
            case .presets: return "square.3.layers.3d.down.right"
            case .background: return "photo.fill"
            case .images: return "photo.on.rectangle"
            case .ratio: return "aspectratio"
            case .text: return "textformat"
            case .zoom: return "arrow.up.left.and.arrow.down.right"
            case .bezel: return "iphone"
            }
        }
    }
    
    @State private var activeTool: EditorTool = .presets
    @Namespace private var tabBarGlassNamespace
    @StateObject private var exporter = MockupExporter()
    
    @State private var drawerState: DrawerState = .expanded
    @State private var drawerProgress: CGFloat = 1.0
    @State private var startDragProgress: CGFloat = 1.0
    @State private var isDragging: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let safeBottom = geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 16
            
            let handleH: CGFloat = 44
            let toolsH: CGFloat = 220
            
            // Floating Tab Bar geometry
            let tabBarContentH: CGFloat = 64
            let tabBarBottomMargin = safeBottom
            let tabBarTopMargin: CGFloat = 16
            let tabBarH = tabBarContentH + tabBarBottomMargin + tabBarTopMargin
            
            let expandedH = handleH + toolsH + tabBarH
            let collapsedH = handleH + tabBarH
            
            // Canvas math for continuous interpolation
            let topInset = 60 + geo.safeAreaInsets.top
            let availC = geo.size.height - topInset - collapsedH
            let availE = geo.size.height - topInset - expandedH
            
            let ratio = document.canvasRatio.ratio(for: document.media, orientation: document.canvasOrientation) ?? (9.0 / 16.0)
            
            let availableRatioC = geo.size.width / max(1, availC)
            let widthC = ratio > availableRatioC ? geo.size.width : availC * ratio
            
            let availableRatioE = geo.size.width / max(1, availE)
            let widthE = ratio > availableRatioE ? geo.size.width : availE * ratio
            
            let targetScale = widthC > 0 ? (widthE / widthC) : 1.0
            let targetOffsetY = (availE - availC) / 2
            
            let currentScale = 1.0 + (targetScale - 1.0) * drawerProgress
            let currentOffsetY = targetOffsetY * drawerProgress
            
            ZStack(alignment: .bottom) {
                // Dark Editor Environment
                Color.editorBackground.ignoresSafeArea()
                
                // Canvas Area
                if document.media != nil {
                    MockupCanvasView(document: document)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, topInset)
                        .padding(.bottom, collapsedH) // Static layout footprint
                        .scaleEffect(currentScale)
                        .offset(y: currentOffsetY)
                } else {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 64, weight: .ultraLight))
                            .foregroundColor(.gray)
                        
                        Text("No Mockup")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos]), photoLibrary: .shared()) {
                            Text("Import Screenshot")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.controlBackground)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Top Floating Controls
                VStack {
                    HStack {
                        PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos]), photoLibrary: .shared()) {
                            Image(systemName: document.media == nil ? "plus" : "photo.badge.arrow.down")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.controlBackground)
                                .clipShape(Circle())
                        }
                        
                        if document.media != nil {
                            Button(action: addTextElement) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.controlBackground)
                                    .clipShape(Circle())
                            }
                        }
                        
                        Spacer()
                        
                        if document.media != nil {
                            if exporter.isExporting {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                        .frame(width: 44, height: 44)
                                    Circle()
                                        .trim(from: 0, to: exporter.exportProgress > 0 ? exporter.exportProgress : 1) // If 0, maybe it's image export and indeterminate
                                        .stroke(Color.screenyOrange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 44, height: 44)
                                    if exporter.exportProgress > 0 {
                                        Text("\(Int(exporter.exportProgress * 100))%")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                }
                                .background(Color.controlBackground)
                                .clipShape(Circle())
                            } else {
                                HStack(spacing: 8) {
                                    Button(action: { exporter.saveToPhotos(document: document) }) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.controlBackground)
                                            .clipShape(Circle())
                                    }
                                    Button(action: { exporter.share(document: document) }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.controlBackground)
                                            .clipShape(Circle())
                                    }
                                    Menu {
                                        Button(role: .destructive, action: {
                                            withAnimation(.easeOut(duration: 0.2)) {
                                                document.media = nil
                                                selectedItem = nil
                                            }
                                        }) {
                                            Label("Remove Image", systemImage: "trash")
                                        }
                                    } label: {
                                        Image(systemName: "gearshape")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.controlBackground)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8 + geo.safeAreaInsets.top)
                    Spacer()
                }
                
                // Drawer
                if document.media != nil {
                    // A. Sliding Sheet (Handle + Active Tools + Full Background)
                    VStack(spacing: 0) {
                        // Drag Handle Area
                        VStack(spacing: 0) {
                            Capsule()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 4)
                        }
                        .frame(height: handleH)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleDrawer()
                        }
                        
                        // Active Tool Content
                        VStack {
                            switch activeTool {
                            case .presets: PresetControls(document: document)
                            case .background: BackgroundControls(document: document)
                            case .images: ImageControls(document: document)
                            case .ratio: RatioControls(document: document)
                            case .text: TextControls(document: document)
                            case .zoom: ZoomControls(document: document)
                            case .bezel: BezelControls(document: document)
                            }
                        }
                        .frame(height: toolsH, alignment: .top)
                        .opacity(drawerProgress) // Tool content opacity (Layer 3 - active content only)
                        .clipped()
                        .allowsHitTesting(drawerState == .expanded)
                        
                        // Footer space so drawer panel covers behind the tab bar
                        Spacer().frame(height: tabBarH)
                    }
                    .frame(height: expandedH, alignment: .top)
                    .background(
                        // Drawer Surface (Layer 1)
                        // Fades out entirely when collapsed, fully solid when expanded
                        Color.panelBackground
                            .opacity(drawerProgress)
                    )
                    .clipShape(.rect(topLeadingRadius: 36, topTrailingRadius: 36))
                    .shadow(color: .black.opacity(0.2 * drawerProgress), radius: 10, y: -5)
                    .offset(y: (1.0 - drawerProgress) * toolsH) // Pure compositing translation
                    .gesture(drawerDragGesture(toolsH: toolsH))
                    .opacity(keyboardHeight > 0 ? 0 : 1)
                    .animation(.easeOut(duration: 0.2), value: keyboardHeight)
                    
                    // B. Persistent Bottom Tab Bar (Liquid Glass)
                    // The tab controls (Layer 3) always exist with opacity 1,
                    // but the OUTER capsule (Layer 2) fades out.
                    VStack(spacing: 0) {
                        if #available(iOS 26.0, *) {
                            ZStack {
                                GlassEffectContainer(spacing: 8) {
                                    // The invisible buttons own hit testing and the native
                                    // interactive/morphing glass lens. The outer surface is
                                    // constrained by this layer's intrinsic 64-point height.
                                    nativeGlassToolTabBarControls(toolsH: toolsH)
                                        .background {
                                            Color.clear
                                                .glassEffect(.regular, in: Capsule())
                                                .opacity(1.0 - drawerProgress)
                                        }
                                }

                                // Render symbols and labels after the coordinated glass
                                // pass so the outer lens never refracts its own controls.
                                toolTabBarLabels()
                                    .allowsHitTesting(false)
                            }
                        } else {
                            fallbackToolTabBarItems(toolsH: toolsH)
                                .background(
                                    Capsule()
                                        .fill(.regularMaterial)
                                        .opacity(1.0 - drawerProgress)
                                )
                        }
                    }
                    .modifier(OldGlassSimulationModifier(progress: 1.0 - drawerProgress))
                    .padding(.horizontal, 24)
                    .padding(.bottom, tabBarBottomMargin)
                    .padding(.top, tabBarTopMargin)
                    .padding(.top, tabBarTopMargin)
                    .zIndex(10) // Ensure it visually occludes the sliding sheet's tools!
                    .gesture(drawerDragGesture(toolsH: toolsH)) // Ensure tab bar also catches vertical drags
                    .opacity(keyboardHeight > 0 ? 0 : 1)
                    .animation(.easeOut(duration: 0.2), value: keyboardHeight)
                }
            }
            .ignoresSafeArea(.all, edges: [.top, .bottom])
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
                if let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight = frame.height
                    }
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }
        }
        .onChange(of: document.selectedElementID) { _, newID in
            if let id = newID,
               let element = document.elements.first(where: { $0.id == id }),
               case .text = element.content {
                selectTool(.text)
            } else if activeTool == .text {
                // Switch back to something else if a non-text element or background is selected,
                // or just leave it. Leaving it is fine, or switch to presets.
                selectTool(.presets)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let movie = try? await newItem?.loadTransferable(type: Movie.self) {
                    withAnimation(.easeIn(duration: 0.25)) {
                        document.media = .video(movie.url)
                    }
                } else if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    withAnimation(.easeIn(duration: 0.25)) {
                        document.media = .image(uiImage)
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: {
                if let img = exporter.sharedImage { return ShareItem(item: img) }
                if let vid = exporter.sharedVideoURL { return ShareItem(item: vid) }
                return nil
            },
            set: { if $0 == nil { exporter.sharedImage = nil; exporter.sharedVideoURL = nil } }
        )) { item in
            ShareSheet(activityItems: [item.item])
        }
        .alert("Export Error", isPresented: Binding(
            get: { exporter.exportError != nil },
            set: { if !$0 { exporter.exportError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exporter.exportError ?? "")
        }
        .alert("Saved to Photos", isPresented: $exporter.showSuccessMessage) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func drawerDragGesture(toolsH: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    startDragProgress = drawerProgress
                }
                
                let totalDelta = -value.translation.height // dragging UP is negative translation -> positive delta
                let progressDelta = totalDelta / toolsH
                
                var newProgress = startDragProgress + progressDelta
                newProgress = min(max(newProgress, 0.0), 1.0)
                
                // Explicitly disable animation for 1:1 tracking
                var transaction = Transaction()
                transaction.animation = nil
                withTransaction(transaction) {
                    drawerProgress = newProgress
                }
            }
            .onEnded { value in
                isDragging = false
                
                // Velocity-aware target selection
                let velocity = -value.velocity.height
                let progressVelocity = velocity / toolsH
                
                // Predict where the finger would naturally end up
                let predictedProgress = drawerProgress + progressVelocity * 0.2
                
                let targetProgress: CGFloat
                
                // Clear flick detection matches Apple Maps character
                if progressVelocity > 1.5 {
                    targetProgress = 1.0 // Flicked up
                } else if progressVelocity < -1.5 {
                    targetProgress = 0.0 // Flicked down
                } else {
                    // Position-based resolution
                    targetProgress = predictedProgress > 0.5 ? 1.0 : 0.0
                }
                
                drawerState = targetProgress > 0.5 ? .expanded : .collapsed
                
                // Animate smoothly to the endpoint from current continuous progress
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    drawerProgress = targetProgress
                }
            }
    }
    
    private func toggleDrawer(target: DrawerState? = nil) {
        let newState = target ?? (drawerState == .collapsed ? .expanded : .collapsed)
        let targetProgress: CGFloat = (newState == .expanded) ? 1.0 : 0.0
        
        drawerState = newState
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            drawerProgress = targetProgress
        }
    }
    
    private func addTextElement() {
        let newText = CanvasElement(
            id: UUID(),
            content: .text(CanvasElement.TextData(string: "New Text", fontName: "System", color: .white)),
            normalizedPosition: CGPoint(x: 0.5, y: 0.5),
            scale: 0.15,
            zIndex: document.elements.count
        )
        withAnimation {
            document.elements.append(newText)
            document.selectedElementID = newText.id
            document.editingTextElementID = newText.id
        }
    }
    
    private func selectTool(_ tool: EditorTool) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            activeTool = tool
        }
        if drawerState == .collapsed {
            toggleDrawer(target: .expanded)
        }
    }

    @available(iOS 26.0, *)
    private func nativeGlassToolTabBarControls(toolsH: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(EditorTool.allCases.filter { $0 != .text }, id: \.self) { tool in
                let isSelected = activeTool == tool
                Button(action: {
                    selectTool(tool)
                }) {
                    Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                    .background(
                        Group {
                            if isSelected {
                                Color.clear
                                    .glassEffect(.regular.interactive(), in: Capsule())
                                    .glassEffectID("selected-tool-lens", in: tabBarGlassNamespace)
                                    .glassEffectTransition(.matchedGeometry)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func toolTabBarLabels() -> some View {
        HStack(spacing: 0) {
            ForEach(EditorTool.allCases.filter { $0 != .text }, id: \.self) { tool in
                let isSelected = activeTool == tool
                VStack(spacing: 4) {
                    Image(systemName: tool.icon)
                        .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .medium : .regular))
                    Text(tool.rawValue)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundColor(isSelected ? .primary : .primary.opacity(0.5))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func fallbackToolTabBarItems(toolsH: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(EditorTool.allCases.filter { $0 != .text }, id: \.self) { tool in
                let isSelected = activeTool == tool
                Button(action: {
                    selectTool(tool)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tool.icon)
                            .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .medium : .regular))
                        Text(tool.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(isSelected ? .primary : .primary.opacity(0.5))
                    .background(
                        Group {
                            if isSelected {
                                Capsule()
                                    .fill(.regularMaterial)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

struct OldGlassSimulationModifier: ViewModifier {
    let progress: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // iOS 26+ uses real Liquid Glass which provides its own depth,
            // so we strip away the old simulation styling to prevent it
            // from interfering with the system renderer's sampling.
            content
        } else {
            content
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        .opacity(progress)
                )
                .shadow(color: .black.opacity(0.15 * progress), radius: 15, y: 8)
        }
    }
}

#Preview {
    EditorView()
}
