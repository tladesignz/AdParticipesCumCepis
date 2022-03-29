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


    public let base: URL

    public var url: URL {
        if let rp = relativePath ?? basename {
            return base.appendingPathComponent(rp)
        }

        return base
    }

    public override var isDir: Bool {
        return url.hasDirectoryPath
    }


    public init(_ url: URL, relativeTo base: URL? = nil) {
        let url = url.resolvingSymlinksInPath()

        let name = url.lastPathComponent
        let relativePath: String?

        if let base = base?.resolvingSymlinksInPath() {
            self.base = base

            let path = url.path
            relativePath = String(path[path.index(path.startIndex, offsetBy: base.path.count + 1)...])
        }
        else {
            self.base = url.deletingLastPathComponent()

            relativePath = nil
        }

        super.init(name: name, relativePath: relativePath)

        if isDir {
            size = children().reduce(0, { $0 + ($1.size ?? 0) })
        }
        else {
            size = fm.size(of: url)
        }
    }


    open override func getThumbnail(_ resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
            if let cgThumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, File.cgThumbnailOptions) {
                return resultHandler(UIImage(cgImage: cgThumbnail), nil)
            }
        }

        resultHandler(nil, nil)
    }

    open override func original(_ resultHandler: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void) {
        resultHandler(url, nil, nil)
    }

    open override func children() -> [Item] {
        return FileManager.default.contentsOfDirectory(at: url).map { File($0, relativeTo: base) }
    }
}
