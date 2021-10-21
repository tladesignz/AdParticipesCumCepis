//
//  File.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 21.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

open class File: Item {

    public let url: URL?

    public init(_ url: URL) {
        self.url = url

        super.init(name: url.lastPathComponent)

        size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int64
    }


    open override func getThumbnail(_ resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        resultHandler(nil, nil)
    }

    open override func getOriginal(_ resultHandler: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void) {
        resultHandler(url, nil, nil)
    }
}
