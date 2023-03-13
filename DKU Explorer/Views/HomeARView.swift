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
    
    var timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {t in updateView(t)})
    
    func setRecognizedObject(_ newObjectName: String) {
        self.recognizedObject = newObjectName
    }
    
    func setBoundingBox(_ boundingBox: CGRect) {
        self.boundingBox = boundingBox
    }
    
    func getObjectCentralPoint() -> CGPoint {
        // TODO: find the central point of the bounding box then return
        return CGPoint(x: 0, y: 0)
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
    let session = arview.session
    let model = recogd.model
    
    // capture image on the current frame
    let currentImageBuffer: CVImageBuffer? = session.currentFrame?.capturedImage
    if currentImageBuffer == nil {
        print("Current image is nill.")
        return
    }
    
    let currentCIImage = CIImage(cvImageBuffer: currentImageBuffer!)
    
    let request = VNCoreMLRequest(model: model) {
        (request, error) in
        guard let results = request.results as? [VNRecognizedObjectObservation],
              error == nil else {
            fatalError("Failed to perform object detection: \(error!.localizedDescription)")
        }
        
        if results.count == 0 {
            print("the result is empty")
            return
        }
        
        // handle results
        let boundingBox = results[0].boundingBox
        let label = results[0].labels[0]
        let confidence = label.confidence
        let identifier = label.identifier
        
        print("BoundingBox: \(boundingBox)")
        print("identifier: \(identifier)")
        print("confidence: \(confidence)")
    }
    
    let inputSize = CGSize(width: 416, height: 416)
    let scaledImage = currentCIImage.transformed(by: CGAffineTransform(scaleX: inputSize.width / currentCIImage.extent.width, y: inputSize.height / currentCIImage.extent.height))
    
    recogd.setCurrentImage(scaledImage)
    
    let imageRequestHandler = VNImageRequestHandler(ciImage: scaledImage, orientation: .right, options: [:])
    
    do {
        try imageRequestHandler.perform([request])
    } catch {
        fatalError("Failed to perform object detection: \(error.localizedDescription)")
    }
    
    // TODO: filter observations (confidence based)
    
    // we only handle 1 object at a time
    //    let topLabelObservation = observations[0].identifier
    //    let firstWord = topLabelObservation.components(separatedBy: [","])[0]
    //    let topLabelInfo = observations[0]
    //
    //    if recogd.recognizedObject != firstWord {
    //        DispatchQueue.main.async {
    //            recogd.setRecognizedObject(firstWord)
    //        }
    //    }
}

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var recogd = ObjectDetector.shared
    
    func makeUIView(context: Context) -> ARView {
        let arview = recogd.arview
        
        return arview
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        let arview = recogd.arview
        let session = arview.session
        
        
    }
    
}

struct HomeARView_Previews: PreviewProvider {
    static var previews: some View {
        HomeARView()
    }
}
