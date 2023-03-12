//
//  HomeARView.swift
//  DKU Explorer
//
import SwiftUI
import RealityKit
import CoreML
import Vision
import Photos

// Debug
extension CIImage {
    func toUIImage() -> UIImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
// Debug
func saveImageToPhotos(image: CIImage) {
    guard let uiImage = image.toUIImage() else { return }
    PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
    }) { saved, error in
        if let error = error {
            print("Error saving image to photo library: \(error.localizedDescription)")
        } else {
            print("Image saved to photo library")
        }
    }
}


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
    
    @Published var model = try! VNCoreMLModel(for: MobileNetV2(configuration: MLModelConfiguration()).model)
    
    @Published var recognizedObject = "nothing"
    
    var timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {t in updateView(t)})
    
    func setRecognizedObject(_ newObjectName: String) {
        self.recognizedObject = newObjectName
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
    }
    request.imageCropAndScaleOption = .centerCrop
    
    // setup handler
    let handler = VNImageRequestHandler(ciImage: currentCIImage, orientation: .right)
    
    do {
        // send the request to the model
        try handler.perform([request])
    } catch {
        print("Error in performing model request")
        print(error)
    }
    
    // get observations
    guard let observations = request.results as? [VNClassificationObservation] else {
        print("No observations")
        return
    }
    
    // TODO: filter observations (confidence based)
    
    // we only handle 1 object at a time
    let topLabelObservation = observations[0].identifier
    let firstWord = topLabelObservation.components(separatedBy: [","])[0]
    
    if recogd.recognizedObject != firstWord {
        DispatchQueue.main.async {
            recogd.setRecognizedObject(firstWord)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var recogd = ObjectDetector.shared
    
    func makeUIView(context: Context) -> ARView {
        let view = recogd.arview
        return view
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

struct HomeARView_Previews: PreviewProvider {
    static var previews: some View {
        HomeARView()
//        DummyARView()
    }
}
