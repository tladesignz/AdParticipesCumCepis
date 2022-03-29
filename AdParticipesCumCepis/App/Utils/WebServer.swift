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

    var mode: WebServer.Mode { get }

    var templateName: String { get }

    var items: [Item] { get }

    var useCsp: Bool { get }

    func context(for item: Item?) -> [String: Any]

    func downloadFinished()
}

open class WebServer: NSObject, GCDWebServerDelegate {

    public enum Mode {
        case share
        case host

        public var serviceName: String {
            switch self {
            case .share:
                return "share"

            case .host:
                return "host"
            }
        }
    }

    public static var shared: WebServer?

    public var staticPath: String {
        return randomizedStaticPath
    }

    public var downloadPath: String {
        return "/download"
    }

    public var running: Bool {
        return webServer.isRunning
    }

    private var delegates = [String: WebServerDelegate]()


    private lazy var webServer: GCDWebServer = {
        let webServer = GCDWebServer()
        webServer.delegate = self

        return webServer
    }()

    private lazy var randomizedStaticPath: String = {
        return "/static_\(UUID().uuidString)/"
    }()

    private let localStaticPath: String

    private var downloadingDelegates = [WebServerDelegate]()


    public init(localStaticPath: String) {
        self.localStaticPath = localStaticPath
    }


    // MARK: Public Methods

    open func start(for host: String, delegate: WebServerDelegate) throws {
        delegates[host] = delegate

        if webServer.isRunning {
            return
        }

        webServer.removeAllHandlers()

        // Items provided by the view controller.
        webServer.addHandler(
            forMethod: "GET", pathRegex: "^/.*$", request: GCDWebServerRequest.self,
            asyncProcessBlock: processItems)

        // Built-in static files.
        webServer.addHandler(
            forMethod: "GET", pathRegex: "^\(staticPath).*$", request: GCDWebServerRequest.self,
            asyncProcessBlock: processStatic)

        // All items as a ZIP file or the single item, if only one.
        webServer.addHandler(
            forMethod: "GET", path: downloadPath, request: GCDWebServerRequest.self,
            asyncProcessBlock: processZip)

        try webServer.start(options: [
            GCDWebServerOption_AutomaticallySuspendInBackground: false,
            GCDWebServerOption_ConnectedStateCoalescingInterval: 10,
            GCDWebServerOption_BindToLocalhost: true,
            GCDWebServerOption_Port: TorManager.webServerPort,
            GCDWebServerOption_ServerName: Bundle.main.displayName])

        Dimmer.shared.start()
    }

    open func stop(for host: String?) {

        if let host = host {
            delegates[host] = nil
        }

        if !delegates.isEmpty {
            return
        }

        stop()
    }

    open func stop() {
        delegates.removeAll()

        // This might get called on start and will crash then, if never run before, so check first.
        if webServer.isRunning {
            webServer.stop()
        }

        Dimmer.shared.stop()
    }

    open func renderTemplate(name: String, context: [String: Any]) throws -> String {
        fatalError("Subclasses need to implement the `renderTemplate()` method.")
    }


    // MARK: GCDWebServerDelegate

    public func webServerDidStart(_ server: GCDWebServer) {
        // Don't allow the system to go to sleep, while we're serving stuff.
        UIApplication.shared.isIdleTimerDisabled = true
    }

    public func webServerDidDisconnect(_ server: GCDWebServer) {
        for delegate in downloadingDelegates {
            delegate.downloadFinished()
        }

        downloadingDelegates.removeAll()
    }

    public func webServerDidStop(_ server: GCDWebServer) {
        // Ok, we're not serving anyhting any longer. Let the system go to sleep again.
        UIApplication.shared.isIdleTimerDisabled = false
    }


    // MARK: Private Methods

    private func processItems(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
        var pc = req.url.pathComponents
        let gzip = req.acceptsGzipContentEncoding
        let delegate = self.delegate(for: req)

        // First component is the root ("/"). Remove.
        pc.removeFirst()

        var items = delegate?.items

        // Render root.
        if pc.isEmpty {
            // If we're in host mode and there's and index.html file,
            // render that for the root folder. Else render the template
            // as defined by the delegate.
            if delegate?.mode == .host, let index = items?.first(where: { $0.basename == "index.html" }) {
                return self.render(index, with: delegate, gzip: gzip, completion)
            }
            else {
                return self.renderTemplate(for: nil, with: delegate, gzip: gzip, completion)
            }
        }

        repeat {
            guard let item = items?.first(where: { $0.basename == pc.first }) else {
                return self.error(404, with: delegate, gzip: gzip, completion)
            }

            if item.isDir {
                if pc.count > 1 {
                    items = item.children()
                    pc.removeFirst()
                }
                else {
                    // If we're in host mode and there's and index.html file,
                    // render that for the folder. Else render the template
                    // as defined by the delegate.
                    if delegate?.mode == .host, let index = item.children().first(where: { $0.basename == "index.html" }) {
                        return self.render(index, with: delegate, gzip: gzip, completion)
                    }
                    else {
                        return self.renderTemplate(for: item, with: delegate, gzip: gzip, completion)
                    }
                }
            }
            else {
                return self.render(item, with: delegate, gzip: gzip, completion)
            }
        } while (true)
    }

    private func processStatic(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
        var pc = req.url.pathComponents
        let gzip = req.acceptsGzipContentEncoding
        let delegate = self.delegate(for: req)

        // First component is the root ("/"). Remove.
        pc.removeFirst()

        // Second component is `staticPath`. Remove that, too.
        pc.removeFirst()

        var url = URL(fileURLWithPath: self.localStaticPath)

        // Put rest of the path onto our internal file-system path.
        pc.forEach { url.appendPathComponent($0) }

        // Clean the path.
        url = URL(fileURLWithPath: GCDWebServerNormalizePath(url.path))

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return self.error(404, with: delegate, gzip: gzip, completion)
        }

        let res = self.respond(with: delegate, file: url, gzip: gzip)
        res.cacheControlMaxAge = 12 * 60 * 60

        completion(res)
    }

    private func processZip(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
        let gzip = req.acceptsGzipContentEncoding

        guard let delegate = self.delegate(for: req),
              delegate.mode == .share
        else {
            return self.processItems(req: req, completion: completion)
        }

        self.downloadingDelegates.append(delegate)

        let items = delegate.items

        guard !items.isEmpty else {
            return self.error(404, with: delegate, gzip: gzip, completion)
        }

        if items.count == 1 && !items.first!.isDir {
            return self.render(items[0], with: delegate, gzip: gzip, completion)
        }

        guard let archive = Archive(accessMode: .create) else {
            return self.error(500, with: delegate, gzip: gzip, completion)
        }

        let group = DispatchGroup()

        self.add(items, to: archive, in: group)

        group.notify(queue: .global(qos: .userInitiated)) {
            guard let data = archive.data else {
                return self.error(500, with: delegate, gzip: gzip, completion)
            }

            let res = self.respond(with: delegate, data, "application/zip")
            res.setValue("attachment; filename=\"\(Bundle.main.displayName).zip\"",
                         forAdditionalHeader: "Content-Disposition")

            completion(res)
        }
    }

    private func delegate(for request: GCDWebServerRequest?) -> WebServerDelegate? {
        var host = request?.url.host

        if host?.isEmpty ?? true {
            if let hostKey = request?.headers.keys.first(where: { $0.lowercased() == "host" }) {
                host = request?.headers[hostKey]
            }
        }

        if let host = host, !host.isEmpty {
            return delegates[host]
        }

        return delegates.first?.value
    }

    private func renderTemplate(for item: Item?, with delegate: WebServerDelegate?, gzip: Bool, _ completion: GCDWebServerCompletionBlock) {
        guard let delegate = delegate else {
            return self.error(404, with: nil, gzip: gzip, completion)
        }

        do {
            let html = try self.renderTemplate(name: delegate.templateName, context: delegate.context(for: item))

            return completion(self.respond(with: delegate, html: html, gzip: gzip))
        }
        catch {
            print("[\(String(describing: type(of: self)))] error: \(error)")
        }

        self.error(500, with: delegate, gzip: gzip, completion)
    }

    private func error(_ statusCode: Int, with delegate: WebServerDelegate?, gzip: Bool, _ completion: GCDWebServerCompletionBlock) {
        var html: String? = nil

        do {
            html = try self.renderTemplate(name: String(statusCode), context: [:])
        }
        catch {
            print("[\(String(describing: type(of: self)))] error: \(error.localizedDescription)")
        }

        if let html = html {
            completion(self.respond(with: delegate, html: html, statusCode: statusCode, gzip: gzip))
        }
        else {
            completion(self.respond(with: delegate, statusCode: statusCode))
        }
    }

    private func render(_ item: Item, with delegate: WebServerDelegate?, gzip: Bool, _ completion: @escaping GCDWebServerCompletionBlock) {
        item.original { file, data, contentType in
            if let file = file {
                completion(self.respond(with: delegate, file: file, gzip: gzip))
            }
            else if let data = data {
                completion(self.respond(with: delegate, data, contentType ?? "application/octet-stream", gzip: gzip))
            }
            else {
                self.error(404, with: delegate, gzip: gzip, completion)
            }
        }
    }

    private func respond(with delegate: WebServerDelegate?, html: String? = nil,
                         _ data: Data? = nil, _ contentType: String? = nil,
                         file: URL? = nil, redirect: URL? = nil, statusCode: Int? = nil,
                         gzip: Bool = false)
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

        res.isGZipContentEncodingEnabled = gzip


        if let statusCode = statusCode {
            res.statusCode = statusCode
        }

        if delegate?.useCsp ?? true {
            res.setValue("default-src 'self'; frame-ancestors 'none'; form-action 'self'; base-uri 'self'; img-src 'self' data:;",
                         forAdditionalHeader: "Content-Security-Policy")
        }

        res.setValue("no-referrer", forAdditionalHeader: "Referrer-Policy")

        res.setValue("nosniff", forAdditionalHeader: "X-Content-Type-Options")

        res.setValue("DENY", forAdditionalHeader: "X-Frame-Options")

        res.setValue("1; mode=block", forAdditionalHeader: "X-Xss-Protection")


        return res
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
                                         uncompressedSize: Int64(data.count),
                                         compressionMethod: .deflate)
                        { position, size in
                            return data.subdata(in: Int(position) ..< Int(position) + size)
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
