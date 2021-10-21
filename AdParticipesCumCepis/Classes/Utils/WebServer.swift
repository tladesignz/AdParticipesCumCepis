//
//  WebServer.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 12.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import GCDWebServer

public protocol WebServerDelegate {

    var templateName: String { get }

    var statusCode: Int { get }

    var context: [String: Any] { get }

    func getItem(name: String, _ completion: @escaping (_ file: URL?, _ data: Data?, _ contentType: String?) -> Void)
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
            guard let delegate = self.delegate else {
                self.notFound(req, completion)

                return
            }

            delegate.getItem(name: req.url.lastPathComponent) { file, data, contentType in
                if let file = file {
                    completion(GCDWebServerFileResponse(file: file.path))
                }
                else if let data = data {
                    completion(GCDWebServerDataResponse(
                        data: data, contentType: contentType ?? "application/octet-stream"))
                }
                else {
                    self.notFound(req, completion)
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

    private func notFound(_ req: GCDWebServerRequest, _ completion: GCDWebServerCompletionBlock) {
        var html: String? = nil

        do {
            html = try self.renderTemplate(name: "404", context: [:])
        }
        catch {
            print("[\(String(describing: type(of: self)))] error: \(error.localizedDescription)")
        }

        if let html = html {
            let res = GCDWebServerDataResponse(html: html)
            res?.statusCode = 404

            completion(res)
        }
        else {
            completion(GCDWebServerDataResponse(statusCode: 404))
        }
    }
}
