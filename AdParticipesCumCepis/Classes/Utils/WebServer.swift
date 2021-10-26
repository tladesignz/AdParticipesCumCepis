//
//  WebServer.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 12.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import GCDWebServer
import ZIPFoundation

public protocol WebServerDelegate {

    var templateName: String { get }

    var items: [Item] { get }

    func context(for item: Item?) -> [String: Any]
}

open class WebServer {

    public var staticPath: String {
        return "/static/"
    }

    public var itemsPath: String {
        return "/items/"
    }

    public var downloadPath: String {
        return "/download"
    }

    var delegate: WebServerDelegate? = nil


    private let webServer = GCDWebServer()


    public init(staticPath: String) {
        // Static files.
        webServer.addHandler(forMethod: "GET", pathRegex: "^\(self.staticPath).*$", request: GCDWebServerRequest.self) { req, completion in
            let pc = self.pathComponents(from: req.url)

            var url = URL(fileURLWithPath: staticPath)

            // Put rest of the path onto our internal file-system path.
            pc.forEach { url.appendPathComponent($0) }

            // Clean the path.
            url = URL(fileURLWithPath: GCDWebServerNormalizePath(url.path))

            guard FileManager.default.isReadableFile(atPath: url.path) else {
                return self.error(404, completion)
            }

            let res = self.respond(file: url)
            res.cacheControlMaxAge = 12 * 60 * 60

            completion(res)
        }

        // The template, the view controller wants rendered.
        webServer.addHandler(forMethod: "GET", path: "/index.html", request: GCDWebServerRequest.self) { req, completion in
            self.renderTemplate(for: nil, completion)
        }

        // Redirect request to root directory to "index.html".
        webServer.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self) {
            return self.respond(redirect: URL(string: "index.html", relativeTo: $0.url))
        }

        // Items provided by the view controller.
        webServer.addHandler(forMethod: "GET", pathRegex: "^\(itemsPath).+$", request: GCDWebServerRequest.self) { req, completion in
            var pc = self.pathComponents(from: req.url)

            var items = self.delegate?.items

            repeat {
                guard let item = items?.first(where: { $0.basename == pc.first }) else {
                    return self.error(404, completion)
                }

                if item.isDir {
                    if pc.count > 1 {
                        items = item.children()
                        pc.removeFirst()
                    }
                    else {
                        return self.renderTemplate(for: item, completion)
                    }
                }
                else {
                    return self.render(item, completion)
                }
            } while (true)
        }

        // All items as a ZIP file or the single item, if only one.
        webServer.addHandler(forMethod: "GET", path: downloadPath, request: GCDWebServerRequest.self) { req, completion in
            guard let items = self.delegate?.items,
                  items.count > 0
            else {
                return self.error(404, completion)
            }

            if items.count == 1 && !items.first!.isDir {
                return self.render(items[0], completion)
            }

            guard let archive = Archive(accessMode: .create) else {
                return self.error(500, completion)
            }

            let group = DispatchGroup()

            self.add(items, to: archive, in: group)

            group.notify(queue: .global(qos: .userInitiated)) {
                guard let data = archive.data else {
                    return self.error(500, completion)
                }

                let res = self.respond(data, "application/zip")
                res.setValue("attachment; filename=\"\(Bundle.main.displayName).zip\"",
                             forAdditionalHeader: "Content-Disposition")

                completion(res)
            }
        }
    }


    // MARK: Public Methods

    open func start() throws {
        try webServer.start(options: [
            GCDWebServerOption_AutomaticallySuspendInBackground: false,
            GCDWebServerOption_BindToLocalhost: true,
            GCDWebServerOption_Port: TorManager.webServerPort,
            GCDWebServerOption_ServerName: Bundle.main.displayName])
    }

    open func stop() {
        webServer.stop()
    }

    open func renderTemplate(name: String, context: [String: Any]) throws -> String {
        fatalError("Subclasses need to implement the `renderTemplate()` method.")
    }


    // MARK: Private Methods

    private func renderTemplate(for item: Item?, _ completion: GCDWebServerCompletionBlock) {
        guard let delegate = self.delegate else {
            return self.error(404, completion)
        }

        do {
            let html = try self.renderTemplate(name: delegate.templateName, context: delegate.context(for: item))

            return completion(self.respond(html: html))
        }
        catch {
            print("[\(String(describing: type(of: self)))] error: \(error)")
        }

        self.error(500, completion)
    }

    private func error(_ statusCode: Int, _ completion: GCDWebServerCompletionBlock) {
        var html: String? = nil

        do {
            html = try self.renderTemplate(name: String(statusCode), context: [:])
        }
        catch {
            print("[\(String(describing: type(of: self)))] error: \(error.localizedDescription)")
        }

        if let html = html {
            completion(self.respond(html: html, statusCode: statusCode))
        }
        else {
            completion(self.respond(statusCode: statusCode))
        }
    }

    private func render(_ item: Item, _ completion: @escaping GCDWebServerCompletionBlock) {
        item.original { file, data, contentType in
            if let file = file {
                completion(self.respond(file: file))
            }
            else if let data = data {
                completion(self.respond(data, contentType ?? "application/octet-stream"))
            }
            else {
                self.error(404, completion)
            }
        }
    }

    private func respond(html: String? = nil, _ data: Data? = nil, _ contentType: String? = nil,
                         file: URL? = nil, redirect: URL? = nil, statusCode: Int? = nil)
    -> GCDWebServerResponse
    {
        let res: GCDWebServerResponse

        if let html = html {
            res = GCDWebServerDataResponse(html: html) ?? GCDWebServerResponse()
        }
        else if let data = data, let contentType = contentType {
            res = GCDWebServerDataResponse(data: data, contentType: contentType)
        }
        else if let file = file {
            res = GCDWebServerFileResponse(file: file.path) ?? GCDWebServerResponse()
        }
        else if let redirect = redirect {
            res = GCDWebServerResponse(redirect: redirect, permanent: false)
        }
        else {
            res = GCDWebServerResponse()
        }

        if let statusCode = statusCode {
            res.statusCode = statusCode
        }


        res.setValue("default-src 'self'; frame-ancestors 'none'; form-action 'self'; base-uri 'self'; img-src 'self' data:;",
                     forAdditionalHeader: "Content-Security-Policy")

        res.setValue("no-referrer", forAdditionalHeader: "Referrer-Policy")

        res.setValue("nosniff", forAdditionalHeader: "X-Content-Type-Options")

        res.setValue("DENY", forAdditionalHeader: "X-Frame-Options")

        res.setValue(" 1; mode=block", forAdditionalHeader: "X-Xss-Protection")


        return res
    }

    private func pathComponents(from url: URL) -> [String] {
        var pc = url.pathComponents

        // First component is the root ("/"). Remove.
        pc.removeFirst()

        // Second component should be the pseudo-folder which determines the route.
        // Remove that, too.
        pc.removeFirst()

        return pc
    }

    private func add(_ items: [Item], to archive: Archive, in group: DispatchGroup) {
        for item in items {
            if item.isDir {
                add(item.children(), to: archive, in: group)

                continue
            }

            group.enter()

            item.original { file, data, _ in
                do {
                    if let file = file {
                        let path: String
                        let baseUrl: URL

                        if let item = item as? File, let rp = item.relativePath {
                            path = rp
                            baseUrl = item.base
                        }
                        else {
                            path = file.lastPathComponent
                            baseUrl = file.deletingLastPathComponent()
                        }

                        try archive.addEntry(with: path,
                                             relativeTo: baseUrl,
                                             compressionMethod: .deflate)
                    }
                    else if let data = data, let name = item.basename, !name.isEmpty {
                        try archive.addEntry(with: name,
                                             type: .file,
                                             uncompressedSize: UInt32(data.count),
                                             compressionMethod: .deflate)
                        { position, size in
                            return data.subdata(in: position ..< position + size)
                        }
                    }
                }
                catch {
                    print("[\(String(describing: type(of: self)))] error: \(error)")
                }

                group.leave()
            }
        }

    }
}
