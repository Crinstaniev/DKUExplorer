//
//  HomeARView.swift
//  DKU Explorer
//
import SwiftUI
import RealityKit
import CoreML
import Vision
import Photos
import SceneKit
import ARKit
import SpriteKit

struct HomeARView: View {
    var body: some View {
        ARViewContainer()
    }
}

class ObjectDetector: ObservableObject {
    // debug use only
    private init() {
    }
    
    static let shared = ObjectDetector()
    
    @Published var arview = ARView()
    
    //    @Published var model = try! VNCoreMLModel(for: MobileNetV2(configuration: MLModelConfiguration()).model)
    @Published var model = try! VNCoreMLModel(for: YOLOv3Tiny(configuration: MLModelConfiguration()).model)
    
    @Published var recognizedObject = "nothing"
    @Published var boundingBox: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    @Published var currentCIImage: CIImage = CIImage()
    
    var frameWidth: CGFloat = 0
    var frameHeight: CGFloat = 0
    
    var timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {t in updateView(t)})
    
    func setRecognizedObject(_ newObjectName: String) {
        self.recognizedObject = newObjectName
    }
    
    func setBoundingBox(_ boundingBox: CGRect) {
        self.boundingBox = boundingBox
    }
    
    func getObjectCentralPoint() -> CGPoint {
        let x = self.boundingBox.midX
        let y = self.boundingBox.midY
        return CGPoint(x: x, y: y)
    }
    
    func setCurrentImage(_ currentCIImage: CIImage) {
        self.currentCIImage = currentCIImage
    }
}


// this function fired periodically
func updateView(_ timer: Timer) {
    print(timer.fireDate)
    
    // setup handy variables
    @ObservedObject var recogd = ObjectDetector.shared
    let arview = recogd.arview
    let model = recogd.model
    
    // Get the current ARFrame
    guard let currentFrame = arview.session.currentFrame else { return }
    
    // Get the camera image size in pixels
    let imageResolution = currentFrame.camera.imageResolution
    let imageSize = CGSize(width: CGFloat(imageResolution.width), height: CGFloat(imageResolution.height))
    
    // Compute the rect for the CIImage
    let imageRect = CGRect(origin: .zero, size: imageSize)
        .aspectFill(to: arview.bounds) // Use an extension method to fit the rect inside the bounds
    
    // Get the camera image as a CVPixelBuffer
    let pixelBuffer = currentFrame.capturedImage
    
    // Convert the CVPixelBuffer to a CIImage
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        .cropped(to: imageRect) // Crop the CIImage to the computed rect
    
//    saveImageToPhotoLibrary(image: CIImage(cvPixelBuffer: pixelBuffer))
    
    recogd.frameHeight = ciImage.extent.height
    recogd.frameWidth = ciImage.extent.width
    
//    print("frameWidth: \(recogd.frameWidth)")
//    print("frameHeight: \(recogd.frameHeight)")
//    print("arBounds: \(recogd.arview.bounds)")
    
    let request = VNCoreMLRequest(model: model) {
        (request, error) in
        guard let results = request.results as? [VNRecognizedObjectObservation],
              error == nil else {
            fatalError("Failed to perform object detection: \(error!.localizedDescription)")
        }
        
        recognitionResultHandler(results)
    }
    
    let inputSize = CGSize(width: 416, height: 416)
    let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: inputSize.width / ciImage.extent.width, y: inputSize.height / ciImage.extent.height))
    
//    saveImageToPhotoLibrary(image: scaledImage)
    
    let imageRequestHandler = VNImageRequestHandler(ciImage: scaledImage, orientation: .right, options: [:])
    
    do {
        try imageRequestHandler.perform([request])
    } catch {
        fatalError("Failed to perform object detection: \(error.localizedDescription)")
    }
}

func recognitionResultHandler(_ results: [VNRecognizedObjectObservation]) {
    // Handle the result
    @ObservedObject var recogd = ObjectDetector.shared

    // return if no observation
    if results.count == 0 {
        print("No object detected")
        return
    }
    
    let observation = results[0]
    let objectBound = VNImageRectForNormalizedRect(observation.boundingBox, Int(recogd.frameWidth), Int(recogd.frameHeight))
    let label = observation.labels[0].identifier
    let confidence = observation.confidence
    
    // return if confidence < 0.5
    if Float(confidence) < 0.5 {
        print("observation not confidence enough: \(confidence)")
        return
    }
    
    print("arbound: \(recogd.arview.bounds)")
    print("objectBound: \(objectBound)")
    print("label: \(label)")
    print("confidence: \(confidence)")
}

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var recogd = ObjectDetector.shared
    
    func makeUIView(context: Context) -> ARView {
        let arview = recogd.arview
        
        return arview
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
    
}

struct HomeARView_Previews: PreviewProvider {
    static var previews: some View {
        HomeARView()
    }
}
