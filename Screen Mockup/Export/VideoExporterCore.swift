import SwiftUI
import AVFoundation

enum VideoExportError: Error {
    case assetReaderFailed
    case assetWriterFailed
    case trackNotFound
    case unreadableFrame
}

@MainActor
final class VideoExporterCore {
    static func exportVideo(document: MockupDocument, session: ProjectSession, videoElementID: UUID, sourceURL: URL, outputURL: URL, canvasSize: CGSize, progress: @escaping (Double) -> Void) async throws {
        let asset = AVURLAsset(url: sourceURL)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoExportError.trackNotFound
        }
        
        let reader = try AVAssetReader(asset: asset)
        let readerOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.add(trackOutput)
        
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let writerOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: canvasSize.width,
            AVVideoHeightKey: canvasSize.height
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: writerOutputSettings)
        writerInput.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: canvasSize.width,
            kCVPixelBufferHeightKey as String: canvasSize.height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        writer.add(writerInput)
        
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: .zero)
        
        let duration = try await asset.load(.duration).seconds
        
        // Create a copy of the document for rendering
        let renderDoc = MockupDocument()
        renderDoc.background = document.background
        renderDoc.backgroundOpacity = document.backgroundOpacity
        renderDoc.canvasRatio = document.canvasRatio
        renderDoc.canvasOrientation = document.canvasOrientation
        renderDoc.elements = document.elements
        
        // Since we can't easily wait for ImageRenderer in a while loop on the main thread without blocking UI updates completely,
        // we process frame by frame with Task.yield() to allow UI to breathe.
        
        let ciContext = CIContext()
        
        while reader.status == .reading {
            if writerInput.isReadyForMoreMediaData {
                if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                    let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    let pTimeSec = presentationTime.seconds
                    
                    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                        if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                            let uiImage = UIImage(cgImage: cgImage)
                            
                            // Set the media to an image containing this specific frame
                            let frameID = UUID()
                            let frameRef = MediaReference(assetID: frameID, kind: .image, pixelSize: uiImage.size, duration: nil)
                            await session.assetStore.cacheImage(uiImage, for: frameID)
                            if let index = renderDoc.elements.firstIndex(where: { $0.id == videoElementID }),
                               case .device(var data) = renderDoc.elements[index].content {
                                data.media = frameRef
                                renderDoc.elements[index].content = .device(data)
                            }
                            
                            // Render the SwiftUI view
                            let rendererView = MockupCompositionView(document: renderDoc, canvasSize: canvasSize)
                                .environment(\.projectAssetStore, session.assetStore)
                                .frame(width: canvasSize.width, height: canvasSize.height)
                            
                            let renderer = ImageRenderer(content: rendererView)
                            renderer.scale = 1.0
                            renderer.proposedSize = .init(canvasSize)
                            
                            if let frameCGImage = renderer.cgImage {
                                // Write to pixel buffer
                                var pixelBuffer: CVPixelBuffer?
                                CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, adaptor.pixelBufferPool!, &pixelBuffer)
                                
                                if let pixelBuffer = pixelBuffer {
                                    CVPixelBufferLockBaseAddress(pixelBuffer, [])
                                    let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                                            width: Int(canvasSize.width),
                                                            height: Int(canvasSize.height),
                                                            bitsPerComponent: 8,
                                                            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                            space: CGColorSpaceCreateDeviceRGB(),
                                                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
                                    context?.draw(frameCGImage, in: CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height))
                                    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                                    
                                    adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                                }
                            }
                        }
                    }
                    progress(pTimeSec / duration)
                    await Task.yield()
                } else {
                    writerInput.markAsFinished()
                    break
                }
            } else {
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }
        
        if reader.status == .failed {
            throw VideoExportError.assetReaderFailed
        }
        
        await writer.finishWriting()
        if writer.status == .failed {
            throw VideoExportError.assetWriterFailed
        }
    }
}
