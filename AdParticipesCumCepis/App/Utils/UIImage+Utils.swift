//
//  UIImage+Utils.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 07.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

extension UIImage {

    /**
     Create a QR code image with correction level "M" from the given content.

     - parameter content: The content to encode in a QR code as a `String`.
     - parameter size: The target size. Aspect ratio will be kept.
     - returns: A `UIImage` containing the QR code.
     */
    public class func qrCode(_ content: String, _ size: CGSize) -> UIImage? {
        if let data = content.data(using: .utf8) {
            return qrCode(data, size)
        }

        return nil
    }

    /**
     Create a QR code image with correction level "M" from the given content.

     - parameter content: The content to encode in a QR code as binary `Data`.
     - parameter size: The target size. Aspect ratio will be kept.
     - returns: A `UIImage` containing the QR code.
     */
    public class func qrCode(_ content: Data, _ size: CGSize) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(content, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage,
            let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
                return nil
        }

        // Keep aspect ratio.
        let scale = min(size.width/ciImage.extent.size.width, size.height/ciImage.extent.size.height)
        let size = CGSize(width: ciImage.extent.size.width * scale, height: ciImage.extent.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(size, true, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.interpolationQuality = .none
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(cgImage, in: context.boundingBoxOfClipPath)

        let uiImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return uiImage
    }
}
