//
//  File.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 21.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

open class File: Item {

    private static let cgThumbnailOptions = [
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: Item.thumbnailSize
        ] as CFDictionary


    public let url: URL

    public init(_ url: URL) {
        self.url = url

        super.init(name: url.lastPathComponent)

        size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int64
    }


    open override func getThumbnail(_ resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
            if let cgThumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, File.cgThumbnailOptions) {
                return resultHandler(UIImage(cgImage: cgThumbnail), nil)
            }
        }

        resultHandler(nil, nil)
    }

    open override func getOriginal(_ resultHandler: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void) {
        resultHandler(url, nil, nil)
    }
}
