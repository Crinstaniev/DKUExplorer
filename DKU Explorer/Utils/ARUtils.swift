//
//  ARUtils.swift
//  DKU Explorer
//
//  Created by Crinstaniev on 2023/3/13.
//

import Foundation
import RealityKit
import ARKit


func saveImageToPhotoLibrary(image: CIImage) {
    // Convert the CIImage to a UIImage
    let context = CIContext()
    guard let cgImage = context.createCGImage(image, from: image.extent) else {
        fatalError("Failed to create CGImage from CIImage")
    }
    let uiImage = UIImage(cgImage: cgImage)

    // Save the UIImage to the photo library
    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
}

extension CGRect {
    func aspectFill(to bounds: CGRect) -> CGRect {
        let aspect = self.width / self.height
        let targetAspect = bounds.width / bounds.height
        if aspect > targetAspect {
            let targetWidth = self.height * targetAspect
            let x = (self.width - targetWidth) / 2.0
            return CGRect(x: x, y: self.origin.y, width: targetWidth, height: self.height)
        } else {
            let targetHeight = self.width / targetAspect
            let y = (self.height - targetHeight) / 2.0
            return CGRect(x: self.origin.x, y: y, width: self.width, height: targetHeight)
        }
    }
}
