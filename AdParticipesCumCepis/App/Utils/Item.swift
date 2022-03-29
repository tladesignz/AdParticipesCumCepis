//
//  Item.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 21.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

open class Item: Identifiable {

    public static let thumbnailSize = 160
    
    public let basename: String?

    public let relativePath: String?

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

    public private(set) var link: String?

    public var isDir: Bool {
        return false
    }

    lazy var fm = FileManager.default


    public init(name: String?, relativePath: String? = nil) {
        basename = name
        self.relativePath = relativePath

        if let rp = relativePath ?? name, !rp.isEmpty {
            link = "/\(rp)"

            if isDir && link?.suffix(1) != "/" {
                link! += "/"
            }
        }
    }


    open func getThumbnail(_ resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) {
        preconditionFailure("Implement in subclass!")
    }

    open func original(_ resultHandler: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void) {
        preconditionFailure("Implement in subclass!")
    }

    /**
     Return all children of this item.

     You only need to implement this, if `isDir` can be `true`!
     */
    open func children() -> [Item] {
        preconditionFailure("Implement in subclass!")
    }
}
