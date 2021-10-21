//
//  Item.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 21.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

open class Item {
    
    public let basename: String?

    open var size: Int64? {
        didSet {
            if let size = size {
                size_human = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
            else {
                size_human = nil
            }
        }
    }

    open var size_human: String?

    public let link: String?


    public init(name: String?) {
        basename = name

        if let name = basename, !name.isEmpty {
            link = "/items/\(name)"
        }
        else {
            link = nil
        }
    }


    open func getThumbnail(_ resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        assertionFailure("Implement in subclass!")
    }

    open func getOriginal(_ resultHandler: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void) {
        assertionFailure("Implement in subclass!")
    }
}
