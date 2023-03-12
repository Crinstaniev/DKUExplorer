//
//  HomeARView.swift
//  DKU Explorer
//
//  Created by Crinstaniev on 2023/3/12.
//

import SwiftUI
import RealityKit
import CoreML
import Vision


struct HomeARView: View {
    var body: some View {
         ARViewContainer()
//        Text("This is the AR View")
    }
}

func createObjectDetector() -> VNCoreMLModel {
    let model = try! VNCoreMLModel(for: YOLOv3Int8LUT(configuration: MLModelConfiguration()).model)
    return model
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let model = createObjectDetector()
        
        print(model)
    
//        // Load the "Box" scene from the "Experience" Reality File
//        let boxAnchor = try! Experience.loadBox()
//
//        // Add the box anchor to the scene
//        arView.scene.anchors.append(boxAnchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

struct DummyARView: View {
    var body: some View {
        Text("AR VIEW PLACE HOLDER")
    }
}

struct HomeARView_Previews: PreviewProvider {
    static var previews: some View {
        HomeARView()
//        DummyARView()
    }
}
