//
//  Document.swift
//  AdParticipesCumCepis.default-Shared
//
//  Created by Benjamin Erhart on 30.03.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation

open class Document: File {

    open var bookmark: Data?

    public var contents = [Document]()

    open override var url: URL {
        var stale = false

        if let bookmark = bookmark {
            let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &stale)

            if let url = url, !stale {
                return url
            }
        }

        return super.url
    }

    public init(_ url: URL, relativeTo base: URL? = nil) {
        let scope = url.startAccessingSecurityScopedResource()

        bookmark = try? url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil, relativeTo: nil)

        super.init(url, relativeTo: base, evaluateSize: false)

        if isDir {
            contents = fm.contentsOfDirectory(at: url).map { Document($0, relativeTo: self.base) }

            size = contents.reduce(0, { $0 + ($1.size ?? 0) })
        }
        else {
            size = fm.size(of: url)
        }

        if scope {
            url.stopAccessingSecurityScopedResource()
        }
    }

    open override func getThumbnail(_ resultHandler: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
        let scope = url.startAccessingSecurityScopedResource()

        super.getThumbnail(resultHandler)

        if scope {
            url.stopAccessingSecurityScopedResource()
        }
    }

    open override func original(_ resultHandler: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void) {
        let scope = url.startAccessingSecurityScopedResource()

        resultHandler(url, nil, nil)

        if scope {
            url.stopAccessingSecurityScopedResource()
        }
    }

    open override func children() -> [Item] {
        return contents
    }

    open override func remove() throws {
        // Ignored. We don't delete foreign files.
    }
}
