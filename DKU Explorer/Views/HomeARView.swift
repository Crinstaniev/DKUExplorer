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
        let arview = recogd.arview
        
        return arview
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        let arview = recogd.arview
        let session = arview.session
        
        // Create an anchor at the center of the screen
        let anchor = ARAnchor(transform: arview.cameraTransform.matrix)
        
        session.add(anchor: anchor)
        
        var txt = SCNText()
        
        // let's keep the number of anchors to no more than 1 for this demo
        if recogd.arview.scene.anchors.count > 0 {
            recogd.arview.scene.anchors.removeAll()
        }
        
        // create the AR Text to place on the screen
        txt = SCNText(string: recogd.recognizedObject, extrusionDepth: 1)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.magenta
        txt.materials = [material]
        
        let shader = SimpleMaterial(color: .blue, roughness: 1, isMetallic: true)
        let text = MeshResource.generateText(
            "\(recogd.recognizedObject)",
            extrusionDepth: 0.05,
            font: .init(name: "Helvetica", size: 0.05)!,
            alignment: .center
        )
        
        let textEntity = ModelEntity(mesh: text, materials: [shader])
        
        let transform = recogd.arview.cameraTransform
        let trans = transform.matrix
        
        let anchEntity = AnchorEntity(world: trans)
        
        textEntity.position.z -= 0.5 // place the text 1/2 meter away from the camera along the Z axis
        
        // find the width of the entity in order to have the text appear in the center
        let minX = text.bounds.min.x
        let maxX = text.bounds.max.x
        let width = maxX - minX
        let xPos = width / 2
        
        textEntity.position.x = transform.translation.x - xPos
        
        anchEntity.addChild(textEntity)
        
        recogd.arview.scene.addAnchor(anchEntity)
    }
    
}



struct HomeARView_Previews: PreviewProvider {
    static var previews: some View {
        HomeARView()    }
}
