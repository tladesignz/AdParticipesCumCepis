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

    var statusCode: Int { get }

    var context: [String: Any] { get }

    var items: [Item] { get }
}

open class WebServer {

    var delegate: WebServerDelegate? = nil


    private let webServer = GCDWebServer()


    public init(staticPath: String) {
        // Static files.
        webServer.addGETHandler(
            forBasePath: "/", directoryPath: staticPath,
            indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)

        // The template, the view controller wants rendered.
        webServer.addHandler(forMethod: "GET", path: "/index.html", request: GCDWebServerRequest.self) { _ in
            var html = "<html><body><h1>Internal Server Error</h1></body></html>"
            var statusCode = 500

            do {
                html = try self.renderTemplate(name: self.delegate?.templateName ?? "404",
                                               context: self.delegate?.context ?? [:])

                statusCode = self.delegate?.statusCode ?? 404
            }
            catch {
                print("[\(String(describing: type(of: self)))] error: \(error.localizedDescription)")
            }

            let res = GCDWebServerDataResponse(html: html)
            res?.statusCode = statusCode

            return res
        }

        // Redirect request to root directory to "index.html".
        webServer.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self) {
            return GCDWebServerResponse(redirect: URL(string: "index.html", relativeTo: $0.url)!, permanent: false)
        }

        // Assets provided by the view controller.
        webServer.addHandler(forMethod: "GET", pathRegex: "/items/.", request: GCDWebServerRequest.self) { req, completion in
            guard let item = self.delegate?.items.first(where: { $0.basename == req.url.lastPathComponent }) else {
                return self.error(404, completion)
            }

            self.getOriginal(item, completion)

        }

        webServer.addHandler(forMethod: "GET", path: "/download", request: GCDWebServerRequest.self) { req, completion in
            guard let items = self.delegate?.items,
                  items.count > 0
            else {
                return self.error(404, completion)
            }

            if items.count == 1 {
                self.getOriginal(items[0], completion)
            }
            else {
                guard let archive = Archive(accessMode: .create) else {
                    return self.error(500, completion)
                }

                let group = DispatchGroup()

                for item in items {
                    group.enter()

                    item.getOriginal { file, data, contentType in
                        if let file = file {
                            try? archive.addEntry(with: item.basename!,
                                                   relativeTo: file.deletingLastPathComponent(),
                                                   compressionMethod: .deflate)
                        }
                        else if let data = data {
                            try? archive.addEntry(with: item.basename!,
                                                   type: .file,
                                                   uncompressedSize: UInt32(data.count),
                                                   compressionMethod: .deflate)
                            { position, size in
                                return data.subdata(in: position ..< position + size)
                            }
                        }

                        group.leave()
                    }
                }

                group.notify(queue: .global(qos: .userInitiated)) {
                    guard let data = archive.data else {
                        return self.error(500, completion)
                    }

                    let res = GCDWebServerDataResponse(data: data, contentType: "application/zip")
                    res.setValue("attachment; filename=\"\(Bundle.main.displayName).zip\"",
                                 forAdditionalHeader: "Content-Disposition")

                    completion(res)
                }
            }
        }
    }


    // MARK: Public Methods

    open func start() throws {
        try webServer.start(options: [
            GCDWebServerOption_Port: TorManager.webServerPort,
            GCDWebServerOption_AutomaticallySuspendInBackground: false])
    }

    open func stop() {
        webServer.stop()
    }

    open func renderTemplate(name: String, context: [String: Any]) throws -> String {
        fatalError("Subclasses need to implement the `renderTemplate()` method.")
    }


    // MARK: Private Methods

    private func error(_ statusCode: Int, _ completion: GCDWebServerCompletionBlock) {
        var html: String? = nil

        do {
            html = try self.renderTemplate(name: String(statusCode), context: [:])
        }
        catch {
            print("[\(String(describing: type(of: self)))] error: \(error.localizedDescription)")
        }

        if let html = html {
            let res = GCDWebServerDataResponse(html: html)
            res?.statusCode = statusCode

            completion(res)
        }
        else {
            completion(GCDWebServerDataResponse(statusCode: statusCode))
        }
    }

    private func getOriginal(_ item: Item, _ completion: @escaping GCDWebServerCompletionBlock) {
        item.getOriginal { file, data, contentType in
            if let file = file {
                completion(GCDWebServerFileResponse(file: file.path))
            }
            else if let data = data {
                completion(GCDWebServerDataResponse(
                    data: data, contentType: contentType ?? "application/octet-stream"))
            }
            else {
                self.error(404, completion)
            }
        }
    }
}
